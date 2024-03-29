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

        fn new(allocator: std.mem.Allocator) Self {
            return .{ .black_neight = 0, .root = null, .allocator = allocator };
        }

        fn create_node(self: *Self, data: T) !*Node {
            var node = try self.allocator.create(Node);
            node.data = data;
            return node;
        }

        pub fn insert(self: *Self, data: T) !void {
            self.root = try do_insert(self, data, self.root);
        }

        fn do_insert(self: *Self, data: T, node: ?*Node) !*Node {
            if (node) |n| {
                if (data < n.data) {
                    n.left = try do_insert(self, data, n.left);
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

        pub fn level_order_transversal(self: *Self) void {
            if (self.root == null) {
                return;
            }

            std.debug.print("root data: {} ", .{self.root.?.data});
            const Q = queue.Queue(?*Node);
            var q = Q{};
            var root = Q.Node{ .data = self.root };
            q.push(&root);

            while (!q.is_empty()) {
                const q_node = q.pop();
                if (q_node) |n| {
                    if (n.data) |qn| {
                        std.debug.print("{} ", .{qn.data});

                        if (qn.left != null) {
                            var left_node = Q.Node{ .data = qn.left };
                            q.push(&left_node);
                        }
                        if (qn.right != null) {
                            var right_node = Q.Node{ .data = qn.right };
                            q.push(&right_node);
                        }
                    }
                }
            }
        }
    };
}

// test "create red black tree" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//     var rbtree = RedBlackTree(u32).new(allocator);
//     try rbtree.insert(1);
//     rbtree.level_order_transversal();
// }
