#!/bin/sh
set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
bundle="$repo_root/bin/bundle"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

run_timeout() {
    limit=$1
    shift
    perl -e 'alarm shift; exec @ARGV' "$limit" "$@"
}

out=$(run_timeout 10 "$bundle" "$repo_root/test/fixture/lessons/0001-intro.html") && status=0 || status=$?
[ "$status" -eq 0 ] || fail "good fixture: expected exit 0, got $status"

printf '%s' "$out" | python3 -c "import json,sys; json.load(sys.stdin)" \
    || fail "good fixture: stdout is not valid JSON"

printf '%s' "$out" | python3 -c "
import json, sys
data = json.load(sys.stdin)

assert data['entry'] == 'lessons/0001-intro.html', f\"entry mismatch: {data['entry']!r}\"

expected_keys = {
    'assets/course.css',
    'assets/dot.png',
    'lessons/0001-intro.html',
    'lessons/0002-next.html',
}
actual_keys = set(data['files'].keys())
assert actual_keys == expected_keys, f'files keys mismatch: {actual_keys}'

png = data['files']['assets/dot.png']
assert 'b64' in png and 'text' not in png, f'dot.png entry wrong: {png.keys()}'
assert png['type'] == 'image/png', f\"dot.png type wrong: {png['type']}\"

css = data['files']['assets/course.css']
assert 'text' in css and 'b64' not in css, f'course.css entry wrong: {css.keys()}'
assert css['type'] == 'text/css', f\"course.css type wrong: {css['type']}\"

html = data['files']['lessons/0001-intro.html']['text']
assert not any('example.com' in key for key in data['files']), 'external href leaked into files'
assert not any(key.startswith('data:') for key in data['files']), 'data URI leaked into files'
assert 'https://example.com' in html, 'external href missing from source html'
assert 'data:image/gif' in html, 'data URI missing from source html'

print('good fixture assertions passed')
" || fail "good fixture: JSON assertions failed"

broken_out=$(run_timeout 10 "$bundle" "$repo_root/test/fixture-broken/lessons/0001.html" 2>&1) && broken_status=0 || broken_status=$?
[ "$broken_status" -ne 0 ] || fail "broken fixture: expected non-zero exit, got 0"

printf '%s' "$broken_out" | grep -q "missing.css" || fail "broken fixture: stderr missing 'missing.css'"
printf '%s' "$broken_out" | grep -q "0001.html" || fail "broken fixture: stderr missing referencing file '0001.html'"

echo "all assertions passed"
