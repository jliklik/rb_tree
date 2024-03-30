const std = @import("std");
const queue = @import("queue.zig");

pub fn RedBlackTree(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Color = enum { black, red };

        pub const RotationError = error{ right_child_is_nil, left_child_is_nil };

        pub const Node = struct {
            left: ?*Node = null,
            right: ?*Node = null,
            data: T,
            color: Color = Color.black,
            frequency: u32 = 1,

            pub fn set_left(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }

            pub fn set_right(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }
        };

        root: ?*Node = null,
        parent: ?*Node = null,
        black_neight: u32 = 0,
        allocator: std.mem.Allocator,

        pub fn new(allocator: std.mem.Allocator) Self {
            return .{ .black_neight = 0, .root = null, .allocator = allocator };
        }

        /// Create a new node
        /// By default, new nodes created should be the color red
        fn create_node(self: *Self, data: T) !*Node {
            const node = try self.allocator.create(Node);
            node.* = .{ .data = data, .left = null, .right = null, .color = Color.red, .frequency = 1 };
            return node;
        }

        pub fn insert(self: *Self, data: T) !void {
            self.root = try do_insert(self, data, self.root);
            if (self.root) |root| {
                root.color = Color.black;
            }
        }

        fn do_insert(self: *Self, data: T, node: ?*Node) !*Node {
            if (node) |n| {
                if (data < n.data) {
                    n.left = try do_insert(self, data, n.left);
                    n = rebalance(n, n.left, n.left.left);
                    n = rebalance(n, n.left, n.left.right);
                } else if (data > n.data) {
                    n.right = try do_insert(self, data, n.right);
                } else {
                    n.frequency += 1;
                }
                return n;
            } else {
                const new_node = try create_node(self, data);
                return new_node;
            }
        }

        fn get_sibling(parent: *Node, node: *Node) ?*Node {
            if (parent.left == node) {
                return parent.right;
            } else {
                return parent.left;
            }
        }

        fn sibling_color(parent: *Node, node: *Node) Color {
            if (get_sibling(parent, node)) |sibling| {
                return sibling.color;
            } else {
                return Color.black;
            }
        }

        // https://www.happycoders.eu/algorithms/avl-tree-java/
        //     N             R
        //    / \           / \
        //   L   R         N   RR
        //      / \       / \
        //    RL   RR    L   RL
        // Step 1: N right child becomes RL
        // Step 2: R left child becomes node
        fn rotate_left(node: *Node) !*Node {
            const right_child = node.right;
            if (right_child) |rc| {
                node.right = rc.left;
                rc.left = node;
                return rc;
            } else {
                RotationError.right_child_is_nil;
            }
        }

        // https://www.happycoders.eu/algorithms/avl-tree-java/
        //         N             L
        //        / \           / \
        //       L   R         LL  N
        //      / \               / \
        //     LL  LR            LR  R
        // Step 1: N left child becomes LR
        // Step 2: L right child becomes node
        fn rotate_right(node: *Node) !*Node {
            const left_child = node.right;
            if (left_child) |lc| {
                node.left = lc.right;
                lc.right = node;
                return lc;
            } else {
                RotationError.right_child_is_nil;
            }
        }

        // https://www.youtube.com/watch?v=A3JZinzkMpk
        fn rebalance(self: *Node, child: *Node, grandchild: ?*Node) *Node {
            if (grandchild) |gc| {
                // Case 1: Both parent and uncle are red
                //
                //      Before:                  After:
                //
                //      GP(B)                   GP(R!)
                //     /    \                  /       \
                //    P(R)   U(R)             A(B!)     C(B!)
                //   /                      /
                //  N(R)                  Z(R)
                //
                // Set A and C to black
                // Set Self to Red
                if (gc.color == Color.red and sibling_color(self, child) == Color.red) {
                    child.color = Color.black;
                    var sibling = get_sibling(self, child);
                    sibling.color = Color.black;
                    self.color = Color.red;
                }
                // Case 2: L uncle's is black (Self, A, Z form a triangle)
                //
                //        Before:                  After:                       After2:
                //
                //            P                        P                             L(R)
                //          /   \                    /   \                          /    \
                //        C(B)    N(R)            C(B)   L(R)                      P      N(R)
                //               /   \                   /   \                    / \      / \
                //             L(R)   R                LL    N(R)              C(B)  LL  LR   R
                //            / \                            /  \
                //          LL   LR                        LR    R

                // This is the bottom up approach. Note that thre are actually two approaches:
                // Top down approach
                // - fix as you go down - don't need to walk back up afterwards
                // Bottom up approach
                // - fix after insertion

                // Rotate Z's parent in opposite direction of Z
                // (in this case, right rotate A since Z is in left direction)
                // If A is black, then we are done for now
                // If A is red, notice that this will result in another violation, caused by A
                // This leads to Case 3 (rotate around Z again)

                // Case 3: Z.uncle is black (Self, A, Z form a line)
                //
                //      Before:                  After:
                //
                //      Self(B)                  C(B!)
                //     /      \                 /     \
                //    C(R)     nil            Z(R)   Self(B!)
                //   /   \                            /
                //  Z(R)  X                          X
                //
                // Rotate right on Self
                // Recolor C and Self
                return self;
            } else {
                return self;
            }
        }

        pub fn level_order_transversal(self: *Self) !void {
            if (self.root) |root| {
                var q = queue.Queue(*Node).new(self.allocator);
                try q.push(root);

                while (!q.is_empty()) {
                    const rbtree_node = q.pop();
                    if (rbtree_node) |rbn| {
                        var color = "B";
                        if (rbn.color == Color.red) {
                            color = "R";
                        }
                        std.debug.print("{}{s} ", .{ rbn.data, color });
                        if (rbn.left) |left| {
                            try q.push(left);
                        }
                        if (rbn.right) |right| {
                            try q.push(right);
                        }
                    }
                }
            } else {
                return;
            }
        }
    };
}

test "create red black tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new(allocator);
    try rbtree.insert(5);
    try rbtree.insert(3);
    try rbtree.insert(2);
    try rbtree.insert(4);
    try rbtree.insert(7);
    try rbtree.level_order_transversal();
}
