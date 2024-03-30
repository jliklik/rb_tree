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

        fn create_node(self: *Self, data: T) !*Node {
            const node = try self.allocator.create(Node);
            node.* = .{ .data = data, .left = null, .right = null, .color = Color.black, .frequency = 1 };
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

        pub fn level_order_transversal(self: *Self) !void {
            if (self.root) |root| {
                var q = queue.Queue(*Node).new(self.allocator);
                try q.push(root);

                while (!q.is_empty()) {
                    const rbtree_node = q.pop();
                    if (rbtree_node) |rbn| {
                        std.debug.print("{} ", .{rbn.data});
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
