# zurlencode

`zurlencode` is a CLI utility for URL-encoding and -decoding strings.

## Usage

### Input strings
Use either a positional argument for a single string or pipe it directly from stdin.

```shell
$ zurlencode 'foo bar'
foo%20bar
```

```shell
$ echo -e "foo bar\nbaz quux" | zurlencode
foo%20bar
baz%20quux
```

### Encoding and decoding

With the argument `-t | --type` you specify if you want to _encode_ or _decode_. 

```shell
$ zurlencode -t d 'foo%20bar'
foo bar
```

```shell
$ echo -e "foo%20bar\nbaz%20quux" | zurlencode --type d
foo bar
baz quux
```

## Contributing

Contributing takes place on Codeberg - https://codeberg.org/codedge/zurlencode.
