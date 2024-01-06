const std = @import("std");
const zap = @import("zap");

fn on_request_verbose(r: zap.SimpleRequest) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

fn on_request_minimal(r: zap.SimpleRequest) void {
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

fn help_and_exit(filename: []const u8, err: anyerror) void {
    std.debug.print(
        \\ Error: File `{s}` : {any}
        \\
        \\ To generate both the certificate file and the key file, use the following command:
        \\
        \\ **********************************************************************************************
        \\ ./gen-certs.sh
        \\ **********************************************************************************************
        \\
        \\ After that, run this example again
    ,
        .{ filename, err },
    );
    std.os.exit(1);
}
pub fn main() !void {
    const CERT_FILE = "vemahk.me.crt";
    const KEY_FILE = "vemahk.me.key";

    std.fs.cwd().access(CERT_FILE, .{}) catch |err| {
        help_and_exit(CERT_FILE, err);
    };

    std.fs.cwd().access(KEY_FILE, .{}) catch |err| {
        help_and_exit(KEY_FILE, err);
    };

    const tls = try zap.Tls.init(.{
        .server_name = "localhost:4443",
        .public_certificate_file = CERT_FILE,
        .private_key_file = KEY_FILE,
    });
    defer tls.deinit();

    var listener = zap.SimpleHttpListener.init(.{
        .port = 4443,
        .on_request = on_request_verbose,
        .log = true,
        .max_clients = 100000,
        .tls = tls,
        .public_folder = "./src/public",
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:4443\n", .{});
    std.debug.print("", .{});
    std.debug.print(
        \\
        \\   ***********************************************
        \\   *** Try me with: curl -k -v localhost:4443/ ***
        \\   ***********************************************
        \\
        \\Your browser may lie to you, indicate a non-secure connection because of the self-created certificate, and make you believe that HTTPS / TLS "does not work".
        \\
    , .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1,
    });
}
