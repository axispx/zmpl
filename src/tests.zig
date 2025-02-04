const std = @import("std");
const zmpl = @import("zmpl");
const allocator = std.testing.allocator;
const manifest = @import("zmpl.manifest"); // Generated at build time

test "readme example" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var body = try data.object();
    var user = try data.object();
    var auth = try data.object();

    try user.put("email", data.string("user@example.com"));
    try auth.put("token", data.string("abc123-456-def"));

    try body.put("user", user);
    try body.put("auth", auth);

    if (manifest.find("example")) |template| {
        const output = try template.render(&data);
        defer allocator.free(output);

        try std.testing.expectEqualStrings(
            \\  <div>Email: user@example.com</div>
            \\  <div>Token: abc123-456-def</div>
            \\
            \\  <div><a href="mailto:user@example.com?subject=">user@example.com</a></div>
            \\
            \\  <div><a href="mailto:user@example.com?subject=Welcome to Jetzig!">user@example.com</a></div>
            \\
            \\  <div><a href="mailto:user@example.com?subject=Welcome to Jetzig!">user@example.com</a></div>
            \\
            \\  Use fragment tags when you want to output content without a specific HTML tag
            \\
            \\  Use multi-line raw text tags to bypass Zmpl syntax.
            \\  <code>Some example code with curly braces {} etc.</code>
            \\
            \\  <span>Escape curly braces {like this}</span>
            \\
        , output);
    } else {
        try std.testing.expect(false);
    }
}

test "template with DOS linebreaks" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var body = try data.object();
    var user = try data.object();
    var auth = try data.object();

    try user.put("email", data.string("user@example.com"));
    try auth.put("token", data.string("abc123-456-def"));

    try body.put("user", user);
    try body.put("auth", auth);

    if (manifest.find("example_with_dos_linebreaks")) |template| {
        const output = try template.render(&data);
        defer allocator.free(output);

        try std.testing.expectEqualStrings(
            \\  <div>Email: user@example.com</div>
            \\  <div>Token: abc123-456-def</div>
            \\
            \\  <div><a href="mailto:user@example.com?subject=">user@example.com</a></div>
            \\
            \\  Use fragment tags when you want to output content without a specific HTML tag
            \\
            \\  Use multi-line raw text tags to bypass Zmpl syntax.
            \\  <code>Some example code with curly braces {} etc.</code>
            \\
            \\  <span>Escape curly braces {like this}</span>
            \\
        , output);
    } else {
        try std.testing.expect(false);
    }
}

test "template with if statement" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    try object.put("foo", data.string("bar"));

    const template = manifest.find("example_with_if_statement");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("  <div>Hi!</div>\n", output);
}

test "template with multi-line tag" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_multi_line_tag");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<div>
        \\  <div foo="bar"
        \\       bar="baz"
        \\       qux="foo bar baz
        \\            qux quux corge">hello</div>
        \\</div>
        \\
    , output);
}

test "template with quotes" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_quotes");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>\"Hello!\"</div>\n", output);
}

test "template with nested data lookup" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var nested_object = try data.object();
    try nested_object.put("bar", data.integer(10));
    try object.put("foo", nested_object);

    const template = manifest.find("example_with_nested_data_lookup");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>Hello 10!</div>\n", output);
}

test "template with array data lookup" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var nested_array = try data.array();
    try nested_array.append(data.string("nested array value"));
    try object.put("foo", nested_array);

    const template = manifest.find("example_with_array_data_lookup");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>Hello nested array value!</div>\n", output);
}

test "template with root array" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var array = try data.array();
    try array.append(data.string("root array value"));

    const template = manifest.find("example_with_root_array");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>Hello root array value!</div>\n", output);
}

test "template with deep nesting" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var nested_object = try data.object();
    var double_nested_object = try data.object();
    var triple_nested_object = try data.object();
    try triple_nested_object.put("qux", data.string(":))"));
    try double_nested_object.put("baz", triple_nested_object);
    try nested_object.put("bar", double_nested_object);
    try object.put("foo", nested_object);

    const template = manifest.find("example_with_deep_nesting");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>Hello :))</div>\n", output);
}

test "template with toJson call" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var nested_object = try data.object();
    var double_nested_object = try data.object();
    var triple_nested_object = try data.object();
    try triple_nested_object.put("qux", data.string(":))"));
    try double_nested_object.put("baz", triple_nested_object);
    try nested_object.put("bar", double_nested_object);
    try object.put("foo", nested_object);

    const template = manifest.find("example_with_toJson_call");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<script>const foo = {"foo":{"bar":{"baz":{"qux":":))"}}}};</script>
        \\
    , output);
}

test "template with iteration" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var array = try data.array();
    try array.append(data.string("yay"));
    try array.append(data.string("hooray"));
    try object.put("foo", array);

    const template = manifest.find("example_with_iteration");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("  <span>yay</span>\n  <span>hooray</span>\n", output);
}

test "template with local variable reference" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_local_variable_reference");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<div>Hello there!</div>\n", output);
}

test "template with string literal" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_string_literal");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<button>
        \\  <span>bar</span>
        \\</button>
        \\
    , output);
}

test "template with Zig literal" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_zig_literal");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings("<span>false</span>\n", output);
}

test "template with complex content" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var array = try data.array();
    try array.append(data.string("hello"));
    try array.append(data.string("hi"));
    try array.append(data.string("howdy"));
    try array.append(data.string("hiya"));
    try array.append(data.string("good day"));
    const template = manifest.find("example_with_complex_content");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(output,
        \\<html>
        \\    <div>Hi</div>
        \\
        \\  <div style="background-color: #ff0000">
        \\    <ol>
        \\        <li>This is item number 1, one</li>
        \\        <li>This is item number 2, two</li>
        \\        <li>This is item number 3, three</li>
        \\        <li>This is item number 4, four</li>
        \\        <li>This is item number 5, five</li>
        \\        <li>This is item number 6, six</li>
        \\        <li>This is item number 7, seven</li>
        \\        <li>This is item number 8, eight</li>
        \\        <li>This is item number 9, nine</li>
        \\    </ol>
        \\  </div>
        \\
        \\  <ol>
        \\
        \\        <div>hello</div>
        \\        <div>hi</div>
        \\        <div>howdy</div>
        \\        <div>hiya</div>
        \\        <div>good day</div>
        \\  </ol>
        \\
        \\  <span></span>
        \\  <span>hello</span>
        \\  <span>hi</span>
        \\  <span>howdy</span>
        \\  <span>hiya</span>
        \\  <span>good day</span>
        \\</html>
        \\
    );
}

test "template with fragment tag" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_fragment_tag");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<div>
        \\  some text in a fragment
        \\</div>
        \\
    , output);
}

test "template with multi-line fragment tag" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_multi_line_fragment_tag");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<pre><code class="language-zig">
        \\// src/app/views/users.zig
        \\const std = @import("std");
        \\const jetzig = @import("jetzig");
        \\
        \\const Request = jetzig.http.Request;
        \\const Data = jetzig.data.Data;
        \\const View = jetzig.views.View;
        \\
        \\pub fn get(id: []const u8, request: *Request, data: *Data) !View {
        \\  var user = try data.object();
        \\
        \\  try user.put("email", data.string("user@example.com"));
        \\  try user.put("name", data.string("Ziggy Ziguana"));
        \\  try user.put("id", data.integer(id));
        \\  try user.put("authenticated", data.boolean(true));
        \\
        \\  return request.render(.ok);
        \\}
        \\</code></pre>
        \\
    , output);
}

test "template with multi-line fragment tag and trailing content" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_multi_line_fragment_tag_and_trailing_content");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    // XXX: The extra blank line + whitespace is a bug but hopefully enough on an edge case that
    // it won't matter.
    try std.testing.expectEqualStrings(
        \\<div>Some content</div>
        \\  some raw content
        \\  
        \\<span>some trailing content</span>
        \\</code></pre>
        \\
    , output);
}

test "template with escaped curly braces" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_escaped_curly_braces");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<div>
        \\  <span>some escaped curly braces: {foo}</span>
        \\</div>
        \\
    , output);
}

test "template with ternary reference" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_ternary_reference");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    try std.testing.expectEqualStrings(
        \\<div class="bar">hello</div>
        \\<div class="foo">hello</div>
        \\
    , output);
}

test "template with partial" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<div>This is an example with a partial</div>
        \\<div><span>An example partial</span></div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with arguments" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial_with_arguments");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<div>This is an example with a partial with arguments</div>
        \\<div><span>An example partial</span>
        \\<span>foo: hello</span>
        \\<span>bar: 100</span></div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with argument type inference" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial_with_argument_type_inference");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    // XXX: `null` (`quux`) coerces an empty string.
    const expected =
        \\<div>This is an example with a partial with arguments with type inference</div>
        \\<div><span>An example partial</span>
        \\<span>foo: hello</span>
        \\<span>bar: 100</span>
        \\<span>baz: 123.456</span>
        \\<span>qux: true</span>
        \\<span>quux: </span></div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with arguments with commas and quotes" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial_with_arguments_with_commas_in_quotes");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<div>This is an example with a partial with arguments</div>
        \\<div><span>An example partial</span>
        \\<span>foo: hello, hi: goodbye</span>
        \\<span>bar: 100</span></div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with arguments with escaped quotes" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial_with_arguments_with_escaped_quotes");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<div>This is an example with a partial with arguments</div>
        \\<div><span>An example partial</span>
        \\<span>foo: hello, hi: "foo, bar" goodbye</span>
        \\<span>bar: 100</span></div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with no terminating linebreak" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_with_partial_with_no_terminating_linebreak");
    const output = try template.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<div>
        \\  <div><h1>test of the thing</h1></div>
        \\</div>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

// Not sure how to test this without passing another build option:

// test "template with consts" {
//     var data = zmpl.Data.init(allocator);
//     defer data.deinit();
//
//     try data.addConst("current_view", data.string("iguanas"));
//     try data.addConst("current_action", data.string("index"));
//
//     const template = manifest.find("example_with_consts");
//     const output = try template.?.render(&data);
//     defer allocator.free(output);
//
//     const expected =
//         \\<div>iguanas</div>
//         \\<div>index</div>
//         \\
//     ;
//     try std.testing.expectEqualStrings(expected, output);
// }

test "template with layout" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_for_layout");
    const layout = manifest.find("layout");
    const output = try template.?.renderWithLayout(layout.?, &data);
    defer allocator.free(output);

    const expected =
        \\<html>
        \\  <body>
        \\    <main><div>content inside a layout</div></main>
        \\  </body>
        \\</html>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "template with partial with layout" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const template = manifest.find("example_for_layout_with_partial");
    const layout = manifest.find("layout");
    const output = try template.?.renderWithLayout(layout.?, &data);
    defer allocator.free(output);

    const expected =
        \\<html>
        \\  <body>
        \\    <main><div>This is an example for a layout with a partial</div>
        \\<div><span>An example partial</span></div></main>
        \\  </body>
        \\</html>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "layout direct render" {
    // Layouts should not be rendered directly, but a layout is just a template that _might_
    // reference `zmpl.content`, so this test ensures that this works even if it's not intended
    // usage.
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const layout = manifest.find("layout");
    const output = try layout.?.render(&data);
    defer allocator.free(output);

    const expected =
        \\<html>
        \\  <body>
        \\    <main></main>
        \\  </body>
        \\</html>
        \\
    ;
    try std.testing.expectEqualStrings(expected, output);
}

test "toJson" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var nested_object = try data.object();
    try nested_object.put("bar", data.integer(10));
    try object.put("foo", nested_object);

    const json = try data.toJson();

    try std.testing.expectEqualStrings(json,
        \\{"foo":{"bar":10}}
    );
}

test "toJson with no data" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();
    const json = try data.toJson();

    try std.testing.expectEqualStrings(json, "");
}

test "toPrettyJson" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const input =
        \\{"foo":{"bar":["baz",10],"qux":{"quux":1.4123,"corge":true}}}
    ;
    try data.fromJson(input);

    const json = try data.toPrettyJson();

    try std.testing.expectEqualStrings(
        \\{
        \\  "foo": {
        \\    "bar": [
        \\      "baz",
        \\      10
        \\    ],
        \\    "qux": {
        \\      "quux": 1.4123,
        \\      "corge": true
        \\    }
        \\  }
        \\}
        \\
    , json);
}

test "fromJson simple" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const input =
        \\{"foo":"bar"}
    ;
    try data.fromJson(input);

    const json = try data.toJson();
    try std.testing.expectEqualStrings(json,
        \\{"foo":"bar"}
    );
}

test "fromJson complex" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const input =
        \\{"foo":{"bar":["baz",10],"qux":{"quux":1.4123,"corge":true}}}
    ;
    try data.fromJson(input);

    const json = try data.toJson();

    try std.testing.expectEqualStrings(json,
        \\{"foo":{"bar":["baz",10],"qux":{"quux":1.4123,"corge":true}}}
    );
}

test "fromJson -> toPrettyJson <- fromJson" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const input =
        \\{"foo":{"bar":["baz",10],"qux":{"quux":1.4123,"corge":true}}}
    ;
    try data.fromJson(input);

    const pretty_json = try data.toPrettyJson();

    var data2 = zmpl.Data.init(allocator);
    defer data2.deinit();

    try data2.fromJson(pretty_json);

    const json = try data2.toJson();
    try std.testing.expectEqualStrings(json, input);
}

test "reset" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    const input =
        \\{"foo":"bar"}
    ;
    try data.fromJson(input);

    const json = try data.toJson();
    try std.testing.expectEqualStrings(json,
        \\{"foo":"bar"}
    );
    data.reset();
    const more_json = try data.toJson();
    try std.testing.expectEqualStrings(more_json, ""); // Maybe this should raise an error or return null ?
}

test "read-only access (simpler interface after casting to const pointers/values)" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var things = try data.array();
    try things.append(data.string("foo"));

    if (data.value) |value| {
        switch (value.*) {
            .array => |array| {
                if (array.get(0)) |item| {
                    switch (item.*) {
                        .string => |string| try std.testing.expectEqualStrings(string.value, "foo"),
                        else => unreachable,
                    }
                }
            },
            else => unreachable,
        }
    } else unreachable;
}

test "appending to an array after insertion into object (regression)" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    var array = try data.array();

    try array.append(data.string("bar"));
    try object.put("foo", array);
    try array.append(data.string("baz"));

    const json = try data.toJson();

    try std.testing.expectEqualStrings(json,
        \\{"foo":["bar","baz"]}
    );
}

test "inserting to an object after insertion into array (regression)" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var array = try data.array();
    var object = try data.object();

    try object.put("bar", data.string("baz"));
    try array.append(object);
    try object.put("qux", data.string("quux"));

    const json = try data.toJson();

    try std.testing.expectEqualStrings(json,
        \\[{"bar":"baz","qux":"quux"}]
    );
}

test "array count()" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var array = try data.array();
    try std.testing.expectEqual(array.count(), 0);
    try array.append(data.string("foo"));
    try std.testing.expectEqual(array.count(), 1);
}

test "object count()" {
    var data = zmpl.Data.init(allocator);
    defer data.deinit();

    var object = try data.object();
    try std.testing.expectEqual(object.count(), 0);
    try object.put("foo", data.string("bar"));
    try std.testing.expectEqual(object.count(), 1);
}

test "eql()" {
    var data1 = zmpl.Data.init(allocator);
    defer data1.deinit();
    var object1 = try data1.object();
    var array1 = try data1.array();

    try object1.put("foo", array1);
    try array1.append(data1.string("bar"));

    var data2 = zmpl.Data.init(allocator);
    defer data2.deinit();
    var object2 = try data2.object();
    var array2 = try data2.array();
    try object2.put("foo", array2);
    try array2.append(data2.string("bar"));

    var data3 = zmpl.Data.init(allocator);
    defer data3.deinit();
    var object3 = try data3.object();
    var object4 = try data3.object();
    try object3.put("foo", data3.string("bar"));
    try object4.put("foo", data3.string("baz"));

    try std.testing.expect(data1.eql(&data2));
    try std.testing.expect(object1.eql(object2));
    try std.testing.expect(array1.eql(array2));
    try std.testing.expect(!object1.eql(array2));
    try std.testing.expect(!object1.eql(array2));
    try std.testing.expect(!object3.eql(object4));
}
