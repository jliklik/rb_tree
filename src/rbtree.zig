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
            color: Color,

            pub fn new(data: T) Node {
                return Node{ .left = null, .right = null, .data = data, .color = Color.black };
            }

            pub fn set_left(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }

            pub fn set_right(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }
        };

        root: ?*Node = null,
        black_neight: u32 = 0,

        pub fn insert(self: *Self, data: T) void {
            if (self.black_neight == 0) {
                var new_node = Node.new(data);
                self.root = &new_node;
            } else {
                std.debug.print("{s}", .{"TO DO"});
            }
        }

        pub fn level_order_transversal(self: *Self) void {
            if (self.root == null) {
                return;
            }

            const Q = queue.Queue(?*Node);
            var q = Q{};
            var root = Q.Node{ .data = self.root };
            q.push(&root);

            std.debug.print("{s} ", .{"HELLO"});

            while (!q.is_empty()) {
                const q_node = q.pop() orelse null;
                std.debug.print("{} ", .{q_node.?.data.?.data});

                if (q_node.?.data.?.left != null) {
                    var left_node = Q.Node{ .data = q_node.?.data.?.left };
                    q.push(&left_node);
                }
                if (q_node.?.data.?.right != null) {
                    var right_node = Q.Node{ .data = q_node.?.data.?.right };
                    q.push(&right_node);
                }
            }
        }
    };
}

test "create red black tree" {
    const RBTree = RedBlackTree(u32);
    var rbtree = RBTree{};
    rbtree.insert(1);
    rbtree.level_order_transversal();
}
