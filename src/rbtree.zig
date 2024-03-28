const std = @import("std");

const Color = enum { black, red };

const Node = struct {
    left: ?*Node = null,
    right: ?*Node = null,
    data: u8,
    color: Color.black,

    pub fn new(data: u8) Node {
        return Node{ .left = null, .right = null, .data = data, .color = Color.black };
    }

    pub fn set_left(self: *Node, left_node: *Node) void {
        self.left = left_node;
    }

    pub fn set_right(self: *Node, left_node: *Node) void {
        self.left = left_node;
    }
};

pub const RedBlackTree = struct {
    root: ?*Node = null,
    black_neight: u64,

    pub fn new() RedBlackTree {
        return RedBlackTree{ .root = null, .black_height = 0 };
    }

    pub fn insert(self: *RedBlackTree, data: u8) void {
        if (self.black_neight == 0) {
            self.root = &Node.new(data);
        } else {
            std.debug.print("TO DO");
        }
    }

    pub fn level_order_transversal(self: *RedBlackTree) void {
        if (self.root == null) {
            return;
        }
    }
};

test "create red black tree" {
    var rbtree = RedBlackTree.new();
    rbtree.insert(1);

    // try std.testing.expectEqual(@as(i32, end - 1), cbuffer.most_recent_value());
}
