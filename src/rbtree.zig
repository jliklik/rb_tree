const std = @import("std");
const queue = @import("queue.zig");
// const expect = @import("std").testing.expect;

pub fn RedBlackTree(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Color = enum { red, black, double_black };

        pub const Direction = enum(u1) { left = 0, right = 1 };

        pub const RotationError = error{ right_child_is_nil, left_child_is_nil };

        pub const Node = struct {
            children: [2]?*Node = [_]?*Node{ null, null },
            data: T,
            color: Color = Color.red,
            frequency: u32 = 1,
            height: u32 = 0,
            delete_later: bool = false,

            pub fn set_left(self: *Node, left_node: *Node) void {
                self.children[@intFromEnum(Direction.left)] = left_node;
            }

            pub fn set_right(self: *Node, right_node: *Node) void {
                self.children[@intFromEnum(Direction.right)] = right_node;
            }
        };

        root: ?*Node = null,
        black_height: u32 = 0,

        pub fn new() Self {
            return .{ .black_height = 0, .root = null };
        }

        fn flip_dir(dir: Direction) Direction {
            if (dir == Direction.left) {
                return Direction.right;
            }
            return Direction.left;
        }

        /// Returns the height of a node
        fn height(left: ?*Node, right: ?*Node) u32 {
            if (left) |l| {
                if (right) |r| {
                    if (l.height > r.height) {
                        return l.height + 1;
                    }
                    return r.height + 1;
                }
                return l.height + 1;
            } else if (right) |r| {
                return r.height + 1;
            } else {
                return 0; // both left and right are null
            }
        }

        fn node_color_to_string(rbn: *Node) *const [1:0]u8 {
            if (rbn.color == Color.red) {
                return "R";
            }
            return "B";
        }

        fn print_node(node: *Node) void {
            std.debug.print("{s}", .{"\n"});
            std.debug.print("{}{s}{}", .{ node.data, node_color_to_string(node), node.height });
            std.debug.print("{s}", .{" L:"});
            if (node.children[@intFromEnum(Direction.left)]) |left| {
                std.debug.print("{}{s}{}", .{ left.data, node_color_to_string(left), left.height });
            } else {
                std.debug.print("{s}", .{"null"});
            }
            std.debug.print("{s}", .{" R:"});
            if (node.children[@intFromEnum(Direction.right)]) |right| {
                std.debug.print("{}{s}{}", .{ right.data, node_color_to_string(right), right.height });
            } else {
                std.debug.print("{s}", .{"null"});
            }
        }

        /// Create a new node
        /// By default, new nodes created should be the color red
        fn create_node(self: *Self, data: T) !*Node {
            const node = try self.allocator.create(Node);
            node.* = .{ .data = data, .children = [_]?*Node{ null, null }, .color = Color.red, .frequency = 1, .height = 0 };
            return node;
        }

        pub fn get_data(self: *Self, data: T) ?*Node {
            return do_get_data(self, data, self.root);
        }

        fn do_get_data(self: *Self, data: T, node: ?*Node) ?*Node {
            if (node) |n| {
                if (n.data == data) {
                    return n;
                } else if (n.data > data) {
                    return do_get_data(self, data, n.children[@intFromEnum(Direction.right)]);
                } else {
                    return do_get_data(self, data, n.children[@intFromEnum(Direction.left)]);
                }
            } else {
                return null;
            }
        }

        pub fn insert(self: *Self, node_to_insert: *Node) !void {
            self.root = try do_insert(self, node_to_insert, self.root);
            if (self.root) |root| {
                root.color = Color.black; // Root is always black - recolor it if it isn't
            }
        }

        fn do_insert(self: *Self, node_to_insert: *Node, node: ?*Node) !*Node {
            if (node) |n| {
                // std.debug.print("At node: {} ", .{n.data});
                if (node_to_insert.data < n.data) {
                    n.children[@intFromEnum(Direction.left)] = try do_insert(self, node_to_insert, n.children[@intFromEnum(Direction.left)]);
                    if (n.children[@intFromEnum(Direction.left)]) |left| {
                        var new_n = n;
                        new_n.height = height(left, n.children[@intFromEnum(Direction.right)]);
                        var res =
                            try rebalance(new_n, Direction.left, Direction.left);
                        if (!res.modified) {
                            res = try rebalance(new_n, Direction.left, Direction.right);
                        }
                        std.debug.print("Returning node from left: {} ", .{res.node.data});
                        return res.node;
                    }
                } else if (node_to_insert.data > n.data) {
                    n.children[@intFromEnum(Direction.right)] = try do_insert(self, node_to_insert, n.children[@intFromEnum(Direction.right)]);
                    if (n.children[@intFromEnum(Direction.right)]) |right| {
                        var new_n = n;
                        new_n.height = height(n.children[@intFromEnum(Direction.left)], right);
                        var res =
                            try rebalance(new_n, Direction.right, Direction.left);
                        if (!res.modified) {
                            res = try rebalance(new_n, Direction.right, Direction.right);
                        }
                        std.debug.print("Returning node from right: {} ", .{res.node.data});
                        return res.node;
                    }
                } else {
                    n.frequency += 1;
                }
                return n;
            } else {
                // std.debug.print("Inserting node: {} ", .{node_to_insert.data});
                return node_to_insert;
            }
        }

        // returns null as well
        fn get_sibling(parent: *Node, node: *Node) ?*Node {
            if (parent.children[@intFromEnum(Direction.left)] == node) {
                return parent.children[@intFromEnum(Direction.right)];
            } else {
                return parent.children[@intFromEnum(Direction.left)];
            }
        }

        fn red(node: ?*Node) bool {
            if (node) |n| {
                return (n.color == Color.red);
            } else {
                return false;
            }
        }

        /// Comments use left rotation as example
        /// Left rotation about N:
        /// https://www.happycoders.eu/algorithms/avl-tree-java/
        ///     N             R
        ///    / \           / \
        ///   L   R         N   RR
        ///      / \       / \
        ///    RL   RR    L   RL
        /// Step 1: N right child becomes RL
        /// Step 2: R left child becomes node
        ///
        /// Right rotation about N:
        ///         N             L
        ///        / \           / \
        ///       L   R         LL  N
        ///      / \               / \
        ///     LL  LR            LR  R
        /// Step 1: N left child becomes LR
        /// Step 2: L right child becomes node
        fn rotate(node: *Node, dir: Direction) !*Node {
            const child = node.children[~@intFromEnum(dir)]; // grab child in opposite direction of rotation
            if (child) |r| {
                node.children[~@intFromEnum(dir)] = r.children[@intFromEnum(dir)]; // N's right child becomes R's left child
                r.children[@intFromEnum(dir)] = node; // R's left child becomes the node
                node.height = height(node.children[@intFromEnum(Direction.left)], node.children[@intFromEnum(Direction.right)]); // update heights of N and R
                r.height = height(r.children[@intFromEnum(Direction.left)], r.children[@intFromEnum(Direction.right)]);
                return r;
            } else if (dir == Direction.left) {
                return RotationError.right_child_is_nil;
            } else {
                return RotationError.left_child_is_nil;
            }
        }

        /// https://www.youtube.com/watch?v=A3JZinzkMpk
        /// https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
        /// Returns struct of .{modified? (T/F), new grandparent node}
        fn rebalance(self: *Node, dir_child: Direction, dir_grandchild: Direction) !struct { modified: bool, node: *Node } {
            std.debug.print("{s}{}", .{ " self data: ", self.data });
            const child = self.children[@intFromEnum(dir_child)];
            if (child) |c| {
                std.debug.print("{s}{}", .{ " child data: ", c.data });
                const grandchild = c.children[@intFromEnum(dir_grandchild)];
                if (grandchild) |gc| {
                    const uncle = get_sibling(self, c);
                    std.debug.print("{s}{}", .{ " gc data: ", gc.data });
                    if (red(gc) and red(uncle)) {
                        // Case 1: Both parent and uncle are red
                        //
                        //      Before:                  After:
                        //
                        //      GP(B)                   GP(R!)
                        //     /    \                  /     \
                        //    P(R)   U(R)            P(B!)   U(B!)
                        //   /                      /
                        //  Z(R)                  Z(R)
                        //
                        // Set P and U to black
                        // Set GP to Red
                        c.color = Color.black;
                        if (uncle) |u| {
                            u.color = Color.black;
                        }
                        self.color = Color.red;
                        std.debug.print("{s} ", .{"Case 1"});
                        return .{ .modified = true, .node = self };
                    } else if (red(gc) and red(c) and !red(uncle)) {
                        if (dir_child != dir_grandchild) {
                            // Double rotation
                            // Case 2-1: L uncle's is black and P, GP, L form a triangle (double rotation)
                            //
                            //          Before:           After rotate right on P:     After rotate left on GP:          Recolor:
                            //
                            //           GP(B)                 GP(B)                          L(R)                         L(B!)
                            //          /   \                 /   \                          /    \                       /    \
                            //        U(B)   P(R)           U(B)   L(R)                    GP(B)   P(R)               GP(R!)    P(R)
                            //               /   \                /   \                    / \     /  \                / \      /  \
                            //             L(R)   R             LL    P(R)              U(B)  LL  LR   R            U(B)  LL   LR   R
                            //            / \                         /  \
                            //          LL   LR                     LR    R
                            //
                            // Case 2-2: R uncle's is black and P, GP, R form a triangle (double rotation)
                            //
                            //          Before:           After rotate left on P:     After rotate right on GP:          Recolor:
                            //
                            //          GP(B)                    GP(B)                      R(R)                           R(B!)
                            //          /   \                    /   \                     /   \                          /   \
                            //        P(R)   U(B)              R(R)  U(B)                P(R)  GP(B)                    P(R)  GP(R!)
                            //        /   \                    /  \                     /  \   /  \                    /  \   /  \
                            //       L   R(R)               P(R)   RR                  L   RL RR  U(B)                L   RL RR  U(B)
                            //            / \               /  \
                            //          RL   RR            L    RL
                            //
                            self.children[@intFromEnum(dir_child)] = try rotate(c, dir_child); // child is P
                            const node_to_return = try rotate(self, dir_grandchild); // self is GP
                            gc.color = Color.black; // GC is now at the top
                            self.color = Color.red; // GP becomes red
                            std.debug.print("{s} ", .{"Case 2-1/2-2"});
                            return .{ .modified = true, .node = node_to_return };
                        } else {
                            // Single rotation
                            // Case 3-1: L uncle's is black and P, GP, L form a line (single rotation)
                            //
                            //          Before:              After rotate left on GP:         Recolor:
                            //
                            //           GP(B)                     P(R)                         P(B!)
                            //          /   \                     /    \                       /    \
                            //        U(B)   P(R)               GP(B)   R(R)               GP(R!)    R(R)
                            //              /   \               / \     /  \                / \      /  \
                            //             L    R(R)         U(B)  L  RL    RR           U(B)  L   RL    RR
                            //                  /  \
                            //                RL    RR
                            //
                            const node_to_return = try rotate(self, flip_dir(dir_child));
                            c.color = Color.black;
                            self.color = Color.red;
                            std.debug.print("{s} ", .{"Case 3-1/3-2"});
                            return .{ .modified = true, .node = node_to_return };
                        }
                    }
                    return .{ .modified = false, .node = self };
                } else {
                    return .{ .modified = false, .node = self };
                }
            } else {
                return .{ .modified = false, .node = self };
            }
        }

        /// Find successor node (assumes right subtree is NOT nil)
        /// First go right, then go all the way to the left
        fn get_successor_when_right_subtree_exists(self: *Self, node: *Node) ?*Node {
            if (node.children[@intFromEnum(Direction.right)]) |right| {
                return do_get_successor_when_right_subtree_exists(self, right);
            }
            return null;
        }

        fn do_get_successor_when_right_subtree_exists(self: *Self, node: *Node) ?*Node {
            if (node.children[@intFromEnum(Direction.left)]) |left| {
                return do_get_successor_when_right_subtree_exists(self, left);
            } else {
                return node;
            }
        }

        /// Find predecessor node (assumes left subtree is NOT nil)
        /// First go right, then go all the way to the left
        fn get_predecessor_when_left_subtree_exists(self: *Self, node: *Node) ?*Node {
            if (node.children[@intFromEnum(Direction.left)]) |left| {
                return do_get_predecessor_when_left_subtree_exists(self, left);
            }
            return null;
        }

        fn do_get_predecessor_when_left_subtree_exists(self: *Self, node: *Node) ?*Node {
            if (node.children[@intFromEnum(Direction.right)]) |right| {
                return do_get_predecessor_when_left_subtree_exists(self, right);
            } else {
                return node;
            }
        }

        pub fn delete(self: *Self, data: T) !?*Node {
            std.debug.print("{s}{} ", .{ "\n--- Data to delete: ", data });
            const res = try do_delete(self, data, self.root);
            self.root = res.ptr_reinforcement_node;
            return res.deleted_node;
        }

        /// Double black case
        /// http://mainline.brynmawr.edu/Courses/cs246/spring2016/lectures/16_RedBlackTrees.pdf
        fn do_delete(self: *Self, data: T, node: ?*Node) !struct { ptr_reinforcement_node: ?*Node, deleted_node: ?*Node } {
            if (node) |n| {
                print_node(n);
                // DELETE Step 1: Do normal BST deletion
                // - may have to find successor and replace the node's value with the successor's value
                // - then delete the successor node
                // Note: Either we end up deleting the node itself (leaf), or we end up deleting the successor (leaf or only one child)

                if (n.data == data) {
                    if (n.frequency == 1) {
                        if (n.children[@intFromEnum(Direction.left)]) |left| {
                            if (n.children[@intFromEnum(Direction.right)] != null) {
                                // 2 children
                                var predecessor = get_predecessor_when_left_subtree_exists(self, n);
                                std.debug.print("{s} ", .{"\nFound predecessor:"});
                                if (predecessor) |sc| {
                                    print_node(sc);
                                } else {
                                    std.debug.print("{s} ", .{"\nFailed to find predecessor:"});
                                }
                                const temp = n.data;
                                n.data = predecessor.?.data; // put node data inside successor, keep going down the tree
                                predecessor.?.data = temp;
                                const delete_res = try do_delete(self, data, left);
                                n.children[@intFromEnum(Direction.left)] = delete_res.ptr_reinforcement_node;
                                var res = try fix_double_black(self, n, Direction.left);
                                if (!res.modified) {
                                    res = try fix_double_black(self, n, Direction.right);
                                }
                                res.node.height = height(res.node.children[@intFromEnum(Direction.left)], res.node.children[@intFromEnum(Direction.right)]);
                                print_node(res.node);
                                return .{ .ptr_reinforcement_node = res.node, .deleted_node = delete_res.deleted_node };
                            } else {
                                // u has one left child - the replacement, v, is u's left child
                                delete_recolor(n, left);
                                return .{ .ptr_reinforcement_node = left, .deleted_node = n };
                            }
                        } else if (n.children[@intFromEnum(Direction.right)]) |right| {
                            // u has one right child - the replacement, v, is u's right child
                            delete_recolor(n, right);
                            return .{ .ptr_reinforcement_node = right, .deleted_node = n };
                        } else {
                            // no children
                            std.debug.print("{s}{} ", .{ "\nFound data to delete: ", data });
                            if (red(n) or n == self.root) {
                                return .{ .ptr_reinforcement_node = null, .deleted_node = n };
                            } else {
                                // If the node being deleted is black and non-root - it will become a double black - defer delete until later
                                // so we can handle the double black properly
                                delete_recolor(n, null);
                                return .{ .ptr_reinforcement_node = n, .deleted_node = n };
                            }
                            // set delete flag
                            // in fix_double_black we will delete it there
                        }
                    } else {
                        n.frequency = n.frequency - 1;
                        return .{ .ptr_reinforcement_node = n, .deleted_node = null };
                    }
                } else if (data > n.data) { // recurse otherwise if node.data != data
                    const delete_res = try do_delete(self, data, n.children[@intFromEnum(Direction.right)]);
                    n.children[@intFromEnum(Direction.right)] = delete_res.ptr_reinforcement_node;
                    // Fix double blacks on the way back up
                    var res = try fix_double_black(self, n, Direction.left);
                    if (!res.modified) {
                        res = try fix_double_black(self, n, Direction.right);
                    }
                    res.node.height = height(res.node.children[@intFromEnum(Direction.left)], res.node.children[@intFromEnum(Direction.right)]);
                    print_node(res.node);
                    return .{ .ptr_reinforcement_node = res.node, .deleted_node = delete_res.deleted_node };
                } else {
                    const delete_res = try do_delete(self, data, n.children[@intFromEnum(Direction.left)]);
                    n.children[@intFromEnum(Direction.left)] = delete_res.ptr_reinforcement_node;
                    // Fix double blacks on the way back up
                    var res = try fix_double_black(self, n, Direction.left);
                    if (!res.modified) {
                        res = try fix_double_black(self, n, Direction.right);
                    }
                    res.node.height = height(res.node.children[@intFromEnum(Direction.left)], res.node.children[@intFromEnum(Direction.right)]);
                    print_node(res.node);
                    return .{ .ptr_reinforcement_node = res.node, .deleted_node = delete_res.deleted_node };
                }
            } else {
                // Failed to find item to delete
                return .{ .ptr_reinforcement_node = null, .deleted_node = null };
            }
        }

        // DELETE Step 2: Recolor
        // - look at the node to be deleted (this would be the successor if it applies)
        // - Let u be the node to be deleted (either the original node or the successor node) and v be the child that replaces u.
        // - if u has no children, v is NIL and black
        // - if u has one one child, v, the replacement, is u's child
        // - u CANNOT have 2 children, otherwise we have not found the successor properly
        // - u AND v cannot be red as then this would not have been a valid rb tree
        // - 2a: if u is red and v is black, simply replace u with v - DONE
        //    Before:      After:
        //     U (R)        V(B)
        //      \
        //       V (B)
        // - 2b: if u is black and v is red, then when v replaces u, mark v as black - DONE
        //    Before:      After:         After2:
        //     U(B)         V(R)           V(B!)
        //      \
        //       V(R)
        // - 2c: if u is black and v is black - we get a DOUBLE BLACK - proceed to step 3
        fn delete_recolor(u: *Node, v_or_null: ?*Node) void {
            if (v_or_null) |v| {
                if ((u.color == Color.black) and (v.color == Color.red)) {
                    v.color = Color.black;
                } else if ((u.color == Color.black) and (v.color == Color.black)) {
                    v.color = Color.double_black;
                }
            } else {
                // as if the NIL node took u's place and became double black
                std.debug.print("{s}", .{"\nRecoloring a nil to double black"});
                u.color = Color.double_black;
                u.delete_later = true;
            }
        }

        // Step 3: Dealing with DOUBLE BLACKS - when both U and V are black
        // - V becomes DOUBLE BLACK when it replaces U
        // - let P = the parent of V
        // - let S = the sibling of V
        fn fix_double_black(self: *Self, p: *Node, dir_child: Direction) !struct { modified: bool, node: *Node } {
            const child = p.children[@intFromEnum(dir_child)];
            if (child) |v| {
                std.debug.print("{s}", .{"\nFixing double black: v"});
                print_node(v);
                std.debug.print("{s}", .{"\nFixing double black: p"});
                print_node(p);
                const sibling = get_sibling(p, v);
                if (sibling) |s| {
                    if (v.color == Color.double_black) {
                        if (red(s)) {
                            // - 3a: V's sibling, S, is red -> rotate P to bring up S, recolor S and P.
                            // Continue to cases 3b, 3c, 3d
                            //
                            //    Before:               After:            After2:
                            //        P(B)               S(R)              S(B!)
                            //      /     \             /   \             /   \
                            //     V(DB)  S(R)        P(B)  SR          P(R!)  SR
                            //           /   \       /    \            /    \
                            //          SL   SR     V(DB)  SL        V(DB)   SL
                            // ---
                            // 1) rotate in direction of v to bring S up
                            std.debug.print("{s} ", .{"\nFix double black: Case 3a"});
                            var rs = try rotate(p, dir_child);
                            // 2) recolor S and P
                            rs.color = Color.black;
                            p.color = Color.red;
                            // 3) pushed problem down - continue on to one of cases 3b, 3c, 3d
                            const res = try fix_double_black(self, p, dir_child);
                            rs.children[@intFromEnum(dir_child)] = res.node;
                            return .{ .modified = true, .node = rs };
                        } else if (!red(s) and !red(s.children[@intFromEnum(Direction.left)]) and !red(s.children[@intFromEnum(Direction.right)])) {
                            // - 3b: V's sibling, S, is black and has two black children
                            //    - recolor S red
                            //    - if P is red -> make P black (absorbs V's blackness) -> DONE
                            //    - if P is black -> now P is double black - reiterate up the tree (Call cases 3a-d on P)
                            //    - or in the case of pointer reinforcement, simply return the parent node as a double black
                            //
                            //    Before:              If P was Red:          If P was Black:
                            //        P(B)                P(B!)                    P(DB!)
                            //      /     \              /     \                   /   \
                            //     V(DB)  S(B)         V(B!)  S(R!)             V(B!)  S(R!)
                            //           /   \                /   \                    /   \
                            //        SL(B)   SR(B)        SL(B) SR(B)              SL(B) SR(B)
                            // ---
                            std.debug.print("{s} ", .{"\nFix double black: Case 3b"});
                            // 1) recolor S red
                            s.color = Color.red;
                            v.color = Color.black;
                            if (red(p)) {
                                p.color = Color.black;
                            } else {
                                p.color = Color.double_black;
                            }
                            if (v.delete_later) {
                                std.debug.print("{s}", .{"\nRemoving the placeholder sentinel"});
                                p.children[@intFromEnum(dir_child)] = null;
                                p.height = height(p.children[@intFromEnum(Direction.left)], p.children[@intFromEnum(Direction.right)]);
                                print_node(p);
                            }

                            return .{ .modified = true, .node = p };
                        } else if (!red(s) and red(s.children[~@intFromEnum(dir_child)])) {
                            // - 3c: S is black, S's child further away from V is RED, other child (closer to V) is any color
                            //    - rotate P to bring S up
                            //    - swap colors of S and P, make S's RED child BLACK -> DONE
                            //
                            //       Before:                 After:            After2:
                            //        P(X)                   S(B)              S(X!)
                            //       /    \                 /   \             /   \
                            //     V(DB)  S(B)            P(X)   SR(R)      P(B!)  SR(B!)
                            //           /   \           /    \            /    \
                            //          SL   SR(R)    V(DB)    SL        V(B!)    SL
                            // ---
                            std.debug.print("{s} ", .{"\nFix double black: Case 3c"});
                            // 1) Rotate to bring S up
                            var rs = try rotate(p, dir_child);
                            // 2) recolor S and P
                            const temp_color = p.color;
                            p.color = rs.color;
                            rs.color = temp_color;
                            v.color = Color.black;
                            rs.children[~@intFromEnum(dir_child)].?.color = Color.black;
                            if (v.delete_later) {
                                std.debug.print("{s}", .{"\nRemoving the placeholder sentinel"});
                                p.children[@intFromEnum(dir_child)] = null;
                                p.height = height(p.children[@intFromEnum(Direction.left)], p.children[@intFromEnum(Direction.right)]);
                                print_node(p);
                            }

                            return .{ .modified = true, .node = rs };
                        } else if (!red(s) and red(s.children[@intFromEnum(dir_child)]) and !red(s.children[~@intFromEnum(dir_child)])) {
                            // - 3d: S is black, S's child further away from V is BLACK, other child (closer to V) is RED
                            //    - rotate S to bring up S's RED child
                            //    - swap color of S and S's original RED child
                            //    - proceed to case 3c
                            //
                            //       Before:                After:            After2:
                            //        P(X)                   P(X)              P(X)
                            //       /    \                 /   \             /   \
                            //     V(DB)  S(B)           V(DB)   SL(R)      V(DB)  SL(B!)
                            //           /   \                     \                \
                            //       SL(R)   SR(B)                  S(B)            S(R!)
                            //                                       \                \
                            //                                       SR(B)           SR(B)
                            // ---
                            std.debug.print("{s} ", .{"\nFix double black: Case 3d"});
                            // 1) Rotate to bring S: up
                            var sl = try rotate(s, @enumFromInt(~@intFromEnum(dir_child)));
                            // 2) recolor SL and S
                            sl.color = Color.black;
                            s.color = Color.red;
                            p.children[~@intFromEnum(dir_child)] = sl;
                            // 3) proceed to case 3c
                            return try fix_double_black(self, p, dir_child);
                        } else {
                            std.debug.print("{s} ", .{"\nFix double black: Unrecognized case - A"});
                            return .{ .modified = false, .node = p };
                        }
                        std.debug.print("{s} ", .{"\nFix double black: Unrecognized case - B"});
                        return .{ .modified = false, .node = p };
                    }

                    // v is not double black - no issue
                    return .{ .modified = false, .node = p };
                }

                std.debug.print("{s} ", .{"\nFix double black: V has no sibling"});
                return .{ .modified = false, .node = p };
            }

            // p has no child
            return .{ .modified = false, .node = p };
        }

        pub fn level_order_transversal(self: *Self, dynamic_string: *std.ArrayList(u8)) !void {
            if (self.root) |root| {
                var q = queue.Queue(*Node).new();
                var qnode = queue.Queue(*Node).Node{ .data = root };
                try q.push(&qnode);

                try do_level_order_transversal(&q, dynamic_string);
                // std.debug.print("{s}", .{dynamic_string.items});

                // while (!q.is_empty()) {
                //     const queue_pop_node = q.pop();
                //     if (queue_pop_node) |qpn| {
                //         const rbn = qpn.data;

                //         // var b: [_]u8 = undefined;
                //         // str = try std.fmt.allocPrint(self.allocator, "{s}{}{s}{},", .{ str, rbn.data, node_color_to_string(rbn), rbn.height });
                //         var writer = dynamic_string.writer();
                //         try writer.print("{}{s}{},", .{ rbn.data, node_color_to_string(rbn), rbn.height });

                //         // std.debug.print("{s}{}{s}{} ", .{ "TRAVERSE node: ", rbn.data, node_color_to_string(rbn), rbn.height });
                //         if (rbn.children[@intFromEnum(Direction.left)]) |left| {
                //             qnode = queue.Queue(*Node).Node{ .data = left };
                //             try q.push(&qnode);
                //         }
                //         if (rbn.children[@intFromEnum(Direction.right)]) |right| {
                //             qnode = queue.Queue(*Node).Node{ .data = right };
                //             try q.push(&qnode);
                //         }
                //     }
                // }
            }
            // return str;
        }

        // must use recursion since we are allocating queue nodes on the stack
        pub fn do_level_order_transversal(q: *queue.Queue(*Node), dynamic_string: *std.ArrayList(u8)) !void {
            const qnode = q.pop();
            if (qnode) |qpn| {
                const rbn = qpn.data;

                // var b: [_]u8 = undefined;
                // str = try std.fmt.allocPrint(self.allocator, "{s}{}{s}{},", .{ str, rbn.data, node_color_to_string(rbn), rbn.height });
                var writer = dynamic_string.writer();
                try writer.print("{}{s}{},", .{ rbn.data, node_color_to_string(rbn), rbn.height });

                // std.debug.print("{s}{}{s}{} ", .{ "TRAVERSE node: ", rbn.data, node_color_to_string(rbn), rbn.height });
                if (rbn.children[@intFromEnum(Direction.left)]) |left| {
                    var new_qn = queue.Queue(*Node).Node{ .data = left };
                    try q.push(&new_qn);
                }
                if (rbn.children[@intFromEnum(Direction.right)]) |right| {
                    var new_qn = queue.Queue(*Node).Node{ .data = right };
                    try q.push(&new_qn);
                }
                try do_level_order_transversal(q, dynamic_string);
            }
        }

        pub fn check(self: *Self, allocator: std.mem.Allocator, exp: []const u8) !void {
            var dynamic_string = std.ArrayList(u8).init(allocator);
            defer dynamic_string.deinit();
            try self.level_order_transversal(&dynamic_string);
            std.debug.print("\n{s} ", .{dynamic_string.items});
            std.debug.assert(std.mem.eql(u8, dynamic_string.items, exp));
        }
    };
}

test "red black tree insert 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var rbtree = RedBlackTree(u32).new();
    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n4 = RedBlackTree(u32).Node{ .data = 4 };
    var n10 = RedBlackTree(u32).Node{ .data = 10 };
    var n9 = RedBlackTree(u32).Node{ .data = 9 };

    try rbtree.insert(&n5);
    try rbtree.insert(&n3);

    try rbtree.check(allocator, "5B1,3R0,");

    try rbtree.insert(&n2);
    try rbtree.check(allocator, "3B1,2R0,5R0,");

    try rbtree.insert(&n4);
    try rbtree.check(allocator, "3B2,2B0,5B1,4R0,");

    try rbtree.insert(&n10);
    try rbtree.check(allocator, "3B2,2B0,5B1,4R0,10R0,");

    try rbtree.insert(&n9);
    try rbtree.check(allocator, "3B3,2B0,5R2,4B0,10B1,9R0,");
}

test "red black tree insert 2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n12 = RedBlackTree(u32).Node{ .data = 12 };
    var n19 = RedBlackTree(u32).Node{ .data = 19 };
    var n9 = RedBlackTree(u32).Node{ .data = 9 };
    var n13 = RedBlackTree(u32).Node{ .data = 13 };
    var n23 = RedBlackTree(u32).Node{ .data = 23 };
    var n10 = RedBlackTree(u32).Node{ .data = 10 };

    try rbtree.insert(&n8);
    try rbtree.insert(&n5);
    try rbtree.insert(&n15);
    try rbtree.insert(&n12);
    try rbtree.insert(&n19);
    try rbtree.insert(&n9);
    try rbtree.insert(&n13);
    try rbtree.insert(&n23);
    try rbtree.check(allocator, "8B3,5B0,15R2,12B1,19B1,9R0,13R0,23R0,");
    try rbtree.insert(&n10);
    try rbtree.check(allocator, "12B3,8R2,15R2,5B0,9B1,13B0,19B1,10R0,23R0,");
}

test "red black tree insert 3" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n0 = RedBlackTree(u32).Node{ .data = 0 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n7 = RedBlackTree(u32).Node{ .data = 7 };
    var n6 = RedBlackTree(u32).Node{ .data = 6 };

    try rbtree.insert(&n8);
    try rbtree.insert(&n2);
    try rbtree.insert(&n15);
    try rbtree.insert(&n1);
    try rbtree.insert(&n5);
    try rbtree.insert(&n0);
    try rbtree.insert(&n3);
    try rbtree.insert(&n7);
    try rbtree.check(allocator, "8B3,2R2,15B0,1B1,5B1,0R0,3R0,7R0,");
    try rbtree.insert(&n6);
    try rbtree.check(allocator, "5B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,");
}

// The following RB tree visualizer was used to help develop these test cases
// https://www.cs.usfca.edu/~galles/visualization/RedBlack.html
test "delete leaf" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n0 = RedBlackTree(u32).Node{ .data = 0 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n7 = RedBlackTree(u32).Node{ .data = 7 };
    var n6 = RedBlackTree(u32).Node{ .data = 6 };

    try rbtree.insert(&n8);
    try rbtree.insert(&n2);
    try rbtree.insert(&n15);
    try rbtree.insert(&n1);
    try rbtree.insert(&n5);
    try rbtree.insert(&n0);
    try rbtree.insert(&n3);
    try rbtree.insert(&n7);
    try rbtree.insert(&n6);
    try rbtree.check(allocator, "5B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,");

    _ = try rbtree.delete(6);
    try rbtree.check(allocator, "5B3,2R2,8R1,1B1,3B0,7B0,15B0,0R0,");
}

test "delete recolor case 1, no double black fixing required" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n7 = RedBlackTree(u32).Node{ .data = 7 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n0 = RedBlackTree(u32).Node{ .data = 0 };
    var n4 = RedBlackTree(u32).Node{ .data = 4 };
    var n6 = RedBlackTree(u32).Node{ .data = 6 };

    try rbtree.insert(&n5);
    try rbtree.insert(&n2);
    try rbtree.insert(&n8);
    try rbtree.insert(&n1);
    try rbtree.insert(&n3);
    try rbtree.insert(&n7);
    try rbtree.insert(&n15);
    try rbtree.insert(&n0);
    try rbtree.insert(&n4);
    try rbtree.insert(&n6);
    try rbtree.check(allocator, "5B3,2R2,8R2,1B1,3B1,7B1,15B0,0R0,4R0,6R0,");

    _ = try rbtree.delete(5);
    try rbtree.check(allocator, "4B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,");
}

test "delete - double black - case 3c" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n7 = RedBlackTree(u32).Node{ .data = 7 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n0 = RedBlackTree(u32).Node{ .data = 0 };
    var n6 = RedBlackTree(u32).Node{ .data = 6 };

    try rbtree.insert(&n5);
    try rbtree.insert(&n2);
    try rbtree.insert(&n8);
    try rbtree.insert(&n1);
    try rbtree.insert(&n3);
    try rbtree.insert(&n7);
    try rbtree.insert(&n15);
    try rbtree.insert(&n0);
    try rbtree.insert(&n6);
    try rbtree.check(allocator, "5B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,");

    _ = try rbtree.delete(5);
    try rbtree.check(allocator, "3B3,1R1,8R2,0B0,2B0,7B1,15B0,6R0,");
}

test "delete - double black - case 3b and 3a" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n5 = RedBlackTree(u32).Node{ .data = 5 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n8 = RedBlackTree(u32).Node{ .data = 8 };
    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n7 = RedBlackTree(u32).Node{ .data = 7 };
    var n15 = RedBlackTree(u32).Node{ .data = 15 };
    var n0 = RedBlackTree(u32).Node{ .data = 0 };
    var n6 = RedBlackTree(u32).Node{ .data = 6 };

    try rbtree.insert(&n5);
    try rbtree.insert(&n2);
    try rbtree.insert(&n8);
    try rbtree.insert(&n1);
    try rbtree.insert(&n3);
    try rbtree.insert(&n7);
    try rbtree.insert(&n15);
    try rbtree.insert(&n0);
    try rbtree.insert(&n6);
    try rbtree.check(allocator, "5B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,");

    _ = try rbtree.delete(8);
    try rbtree.check(allocator, "5B3,2R2,7R1,1B1,3B0,6B0,15B0,0R0,");

    _ = try rbtree.delete(7); // case 3b
    try rbtree.check(allocator, "5B3,2R2,6B1,1B1,3B0,15R0,0R0,");

    _ = try rbtree.delete(15);
    _ = try rbtree.delete(6); // case 3a into 3b
    try rbtree.check(allocator, "2B2,1B1,5B1,0R0,3R0,");
}

test "delete double-black case 3d" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n12 = RedBlackTree(u32).Node{ .data = 12 };
    var n10 = RedBlackTree(u32).Node{ .data = 10 };
    var n14 = RedBlackTree(u32).Node{ .data = 14 };
    var n13 = RedBlackTree(u32).Node{ .data = 13 };

    try rbtree.insert(&n12);
    try rbtree.insert(&n10);
    try rbtree.insert(&n14);
    try rbtree.insert(&n13);
    try rbtree.check(allocator, "12B2,10B0,14B1,13R0,");
    _ = try rbtree.delete(10);
    try rbtree.check(allocator, "13B1,12B0,14B0,");
}

test "delete root" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };

    try rbtree.insert(&n1);
    try rbtree.insert(&n3);
    try rbtree.insert(&n2);

    _ = try rbtree.delete(2);
    _ = try rbtree.delete(3);
    _ = try rbtree.delete(1);
    try rbtree.check(allocator, "");
}

test "deleting non-existent data doesn't cause any errors" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n1 = RedBlackTree(u32).Node{ .data = 1 };
    var n3 = RedBlackTree(u32).Node{ .data = 3 };
    var n2 = RedBlackTree(u32).Node{ .data = 2 };

    try rbtree.insert(&n1);
    try rbtree.insert(&n3);
    try rbtree.check(allocator, "1B1,3R0,");
    try rbtree.insert(&n2);
    try rbtree.check(allocator, "2B1,1R0,3R0,");
    _ = try rbtree.delete(6);
    _ = try rbtree.delete(3);
    _ = try rbtree.delete(5);
    try rbtree.check(allocator, "2B1,1R0,");
}

test "inserting and deleting multiple of same value increases frequency" {
    var rbtree = RedBlackTree(u32).new();

    var n2_1 = RedBlackTree(u32).Node{ .data = 2 };
    var n2_2 = RedBlackTree(u32).Node{ .data = 2 };

    try rbtree.insert(&n2_1);
    try rbtree.insert(&n2_2);
    const nd = rbtree.get_data(2);
    std.debug.assert(nd.?.frequency == 2);
    _ = try rbtree.delete(2);
    std.debug.assert(nd.?.frequency == 1);
    _ = try rbtree.delete(2);
    std.debug.assert(nd.?.frequency == 1);
}

test "fire away" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new();

    var n1562 = RedBlackTree(u32).Node{ .data = 1562 };
    var n3848 = RedBlackTree(u32).Node{ .data = 3848 };
    var n58 = RedBlackTree(u32).Node{ .data = 58 };
    var n289 = RedBlackTree(u32).Node{ .data = 289 };
    var n214 = RedBlackTree(u32).Node{ .data = 214 };
    var n5889 = RedBlackTree(u32).Node{ .data = 5889 };
    var n4844 = RedBlackTree(u32).Node{ .data = 4844 };
    var n5249 = RedBlackTree(u32).Node{ .data = 5249 };
    var n2551 = RedBlackTree(u32).Node{ .data = 2551 };

    try rbtree.insert(&n1562);
    try rbtree.insert(&n3848);
    try rbtree.insert(&n58);
    try rbtree.insert(&n289);
    try rbtree.insert(&n214);
    try rbtree.insert(&n5889);
    try rbtree.insert(&n4844);
    try rbtree.insert(&n5249);
    _ = try rbtree.delete(4844);
    try rbtree.check(allocator, "1562B2,214B1,5249R1,58R0,289R0,3848B0,5889B0,");

    try rbtree.insert(&n2551);
    _ = try rbtree.delete(5889);
    try rbtree.check(allocator, "1562B2,214B1,3848R1,58R0,289R0,2551B0,5249B0,");

    _ = try rbtree.delete(289);
    _ = try rbtree.delete(1562);
    _ = try rbtree.delete(214);
    try rbtree.check(allocator, "3848B2,58B1,5249B0,2551R0,");
}
