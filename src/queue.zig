const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            next: ?*Node = null,
            data: T,

            pub fn set_next(self: *Node, next_node: *Node) void {
                self.next = next_node;
            }
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: std.mem.Allocator,

        pub fn new(allocator: std.mem.Allocator) Self {
            return .{ .head = null, .tail = null, .allocator = allocator };
        }

        fn create_node(self: *Self, data: T) !*Node {
            var node = try self.allocator.create(Node);
            node.data = data;
            node.next = null;
            return node;
        }

        pub fn is_empty(self: *Self) bool {
            if ((self.head == self.tail) and (self.head == null)) {
                return true;
            }
            return false;
        }

        pub fn pop(self: *Self) ?T {
            if (self.head) |head| {
                self.head = head.next;
                // last item popped
                if (self.head == null) {
                    self.tail = null;
                }
                const data = head.data;
                self.allocator.destroy(head);
                return data;
            } else {
                return null;
            }
        }

        pub fn push(self: *Self, data: T) !void {
            const node = try create_node(self, data);
            if (self.tail) |tail| {
                tail.next = node;
                self.tail = node;
            } else {
                // first node in queue
                self.head = node;
                self.tail = node;
                return;
            }
        }
    };
}

test "basic Queue test" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var q = Queue(u32).new(allocator);

    try testing.expect(q.pop() == null);
    try testing.expect(q.is_empty() == true);

    try q.push(1);
    try q.push(2);
    try q.push(3);

    try testing.expect(q.pop() == 1);
    try testing.expect(q.pop() == 2);
    try testing.expect(q.pop() == 3);

    try q.push(4);
    try q.push(5);

    try testing.expect(q.pop() == 4);
    try testing.expect(q.pop() == 5);
    try testing.expect(q.pop() == null);
    try testing.expect(q.is_empty() == true);
}
