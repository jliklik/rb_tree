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

        pub fn new() Self {
            return .{ .head = null, .tail = null };
        }

        pub fn new_node(allocator: std.mem.Allocator, data: T) *Node {
            const node = try allocator.create(Queue.Node);
            node.* = .{
                .data = data,
                .next = null,
            };
            return node;
        }

        pub fn is_empty(self: *Self) bool {
            if ((self.head == self.tail) and (self.head == null)) {
                return true;
            }
            return false;
        }

        pub fn pop(self: *Self) ?*Node {
            if (self.head) |popped| {
                self.head = popped.next;
                // last item popped
                if (self.head == null) {
                    self.tail = null;
                }

                return popped;
            } else {
                return null;
            }
        }

        pub fn push(self: *Self, node: *Node) !void {
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
    var q = Queue(u32).new();

    try testing.expect(q.pop() == null);
    try testing.expect(q.is_empty() == true);

    var n1 = Queue(u32).Node{ .data = 1 };
    var n2 = Queue(u32).Node{ .data = 2 };
    var n3 = Queue(u32).Node{ .data = 3 };
    var n4 = Queue(u32).Node{ .data = 4 };
    var n5 = Queue(u32).Node{ .data = 5 };
    try q.push(&n1);
    try q.push(&n2);
    try q.push(&n3);

    try testing.expect(q.pop().?.data == 1);
    try testing.expect(q.pop().?.data == 2);
    try testing.expect(q.pop().?.data == 3);

    try q.push(&n4);
    try q.push(&n5);

    try testing.expect(q.pop().?.data == 4);
    try testing.expect(q.pop().?.data == 5);
    try testing.expect(q.pop() == null);
    try testing.expect(q.is_empty() == true);
}
