# APIClient 0.x

## APIClient 0.0.5

*Dec 10, 2021*

- Make `Configuration` init public - [#10](https://github.com/kean/APIClient/pull/10), thanks to [Theis Egeberg](https://github.com/theisegeberg)
- All `send` methods now return a new `Response<T>` struct containing not just the response value, but also data, request, response, and status code.
- Add `value(for:)` method that returns `T` – a replacement for the old `send` method
- Add `data(for:)` method returning `Response<Data>`
- Add `options`, `head`, and `trace` HTTP methods
- Method `delete` to use `query` instead of `body`

## APIClient 0.0.4

*Dec 8, 2021*

- Add an option to customize the client's port and scheme - [#7](https://github.com/kean/APIClient/pull/7), thanks to [Mathieu Barnachon
](https://github.com/mbarnach)
- Make values in query parameters optional - [#8](https://github.com/kean/APIClient/pull/8), thanks to [Bernhard Loibl](https://github.com/fonkadelic)
- Update example JSON models to match the GitHub API spec - [#5](https://github.com/kean/APIClient/pull/5), thanks to [Arthur Semenyutin](https://github.com/vox-humana)
- Use `iso8601` date decoding and encoding strategies by default and add a way to customize the decoder and encoder
- Add `id` to requests
- Make `Request` properies public

## APIClient 0.0.3

*Nov 28, 2021*

- Make it available on more platforms 

## APIClient 0.0.1

*Nov 23, 2021*

- Initial relase 
