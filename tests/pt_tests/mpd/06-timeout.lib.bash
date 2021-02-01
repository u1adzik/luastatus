pt_testcase_begin

fakempd_spawn

pt_add_fifo "$main_fifo_file"
pt_write_widget_file <<__EOF__
f = assert(io.open('$main_fifo_file', 'w'))
f:setvbuf('line')
f:write('init\n')
$preface
widget = {
    plugin = '$PT_BUILD_DIR/plugins/mpd/plugin-mpd.so',
    opts = {
        port = $port,
        timeout = 0.25,
    },
    cb = function(t)
        if t.what == 'update' then
            f:write(string.format('cb update song=%s status=%s\n', _fmt_kv(t.song), _fmt_kv(t.status)))
        else
            f:write('cb ' .. t.what .. '\n')
        end
    end,
}
__EOF__
pt_spawn_luastatus
exec 3<"$main_fifo_file"
pt_expect_line 'init' <&3
pt_expect_line 'cb connecting' <&3

fakempd_say "OK MPD I-am-actually-a-shell-script"

measure_start

for (( i = 0; i < 3; ++i )); do
    fakempd_expect 'currentsong'
    fakempd_say "Song_Foo: bar"
    fakempd_say "Song_Baz: quiz"
    fakempd_say "OK"

    fakempd_expect 'status'
    fakempd_say "Status_One: ein"
    fakempd_say "Status_Two: zwei"
    fakempd_say "Status_Three: drei"
    fakempd_say "Z: $i"
    fakempd_say "OK"

    fakempd_expect 'idle mixer player'
    pt_expect_line "cb update song={Song_Baz=>quiz,Song_Foo=>bar} status={Status_One=>ein,Status_Three=>drei,Status_Two=>zwei,Z=>$i}" <&3
    measure_check_ms 0

    pt_expect_line "cb timeout" <&3
    measure_check_ms 250

    pt_expect_line "cb timeout" <&3
    measure_check_ms 250

    fakempd_say "OK"
done

fakempd_kill

pt_expect_line 'cb error' <&3

pt_testcase_end
