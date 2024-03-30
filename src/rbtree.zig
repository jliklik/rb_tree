const std = @import("std");
const queue = @import("queue.zig");

pub fn RedBlackTree(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Color = enum { black, red };

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

        fn rotate_right(self: *Node, child: *Node, grandchild: *Node) *Node {}

        // https://www.youtube.com/watch?v=A3JZinzkMpk
        fn rebalance(self: *Node, child: *Node, grandchild: ?*Node) *Node {
            if (grandchild) |gc| {
                // Case 1: Z.uncle is red
                //
                //      Before:                  After:
                //
                //      Self(B)                  Self(R!)
                //     /      \                 /       \
                //    A(R)     C(R)            A(B!)     C(B!)
                //   /                        /
                //  Z(R)                     Z(R)
                //
                // Set A and C to black
                // Set Self to Red
                if (gc.color == Color.red and sibling_color(self, child) == Color.red) {
                    child.color = Color.black;
                    var sibling = get_sibling(self, child);
                    sibling.color = Color.black;
                    self.color = Color.red;
                }
                // Case 2: Z.uncle is black (Self, A, Z form a triangle)
                //
                //        Before:                  After:
                //
                //        Self(B)                  Self(B)
                //       /      \                 /       \
                //      C(B)     A(R)            C(B)      Z(R)
                //              /  \                      / \
                // grandchild Z(R) M                     X   A(R)
                //            / \                            / \
                //           X   Y                          Y   M
                // Double rotation required:
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
                //   /
                //  Z(R)
                //
                // Rotate around C
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
