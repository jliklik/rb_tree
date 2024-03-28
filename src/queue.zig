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

            pub fn new(data: u8) Node {
                return Node{ .next = null, .data = data };
            }

            pub fn set_next(self: *Node, next_node: *Node) void {
                self.next = next_node;
            }
        };

        head: ?*Node = null,
        tail: ?*Node = null,

        pub fn pop(queue: *Self) ?*Node {
            const head = queue.head orelse null; // unwrap the option
            if (head != null) {
                queue.head = head.?.next;
                // last item popped
                if (queue.head == null) {
                    queue.tail = null;
                }
                return head;
            } else {
                return null;
            }
        }

        pub fn push(queue: *Self, node: *Node) void {
            var tail = queue.tail orelse null; // unwrap the option
            if (tail == null) {
                queue.head = node;
                queue.tail = node;
                return;
            }

            tail.?.next = node;
            queue.tail = node;
        }
    };
}

test "basic Queue test" {
    const Q = Queue(u32);
    var q = Q{};

    var one = Q.Node{ .data = 1 };
    var two = Q.Node{ .data = 2 };
    var three = Q.Node{ .data = 3 };
    var four = Q.Node{ .data = 4 };
    var five = Q.Node{ .data = 5 };

    try testing.expect(q.pop() == null);

    q.push(&one);
    q.push(&two);
    q.push(&three);

    try testing.expect(q.pop().?.data == 1);
    try testing.expect(q.pop().?.data == 2);
    try testing.expect(q.pop().?.data == 3);

    q.push(&four);
    q.push(&five);

    try testing.expect(q.pop().?.data == 4);
    try testing.expect(q.pop().?.data == 5);
    try testing.expect(q.pop() == null);
}
