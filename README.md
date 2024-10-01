# Puppeteer Pool

A server application with an API for scraping web pages. It allows you to receive HTML and cookies from specified URLs.

## Running the server

**Building the image**

```sh
docker build --pull --rm -t puppeteer-cluster .
```

**Running the image**

```sh
docker run --name pptr-cluster --init --cap-add=SYS_ADMIN -d -p 3000:3000 puppeteer-cluster
```

`--cap-add=SYS_ADMIN` capability is needed to enable Chromium sandbox that makes the browser more secure. Alternatively, it should be possible to start the browser binary with the `--no-sandbox` flag.

## API Endpoints

| HTTP Method |  Route   |       Description        |
|:-----------:|:--------:|:------------------------:|
|     GET     | /general | Getting HTML and cookies |
|     GET     |  /html   |       Getting HTML       |

Endpoint `/html` can be useful for debugging in the browser. For example, searching for DOM elements using DevTools.

### Request Parameters

| Parameter  |  Type  |       Default        | Description                         |
|:-----------|:------:|:--------------------:|:------------------------------------|
| `url`      | string |       Required       | URL to scrape                       |
| `selector` | string | Required **(/html)** | CSS selector to wait for in the DOM |
| `timeout`  | number |        30000         | Maximum wait time in milliseconds   |

Maximum page load time is restricted to 60 seconds (1 minute).

### Success response

```json
{
  "status": 200,
  "content": "<html><body><h1>Hello, World!</h1></body></html>",
  "cookies": [
    {
      "name": "cookie_name",
      "value": "cookie_value",
      "domain": ".example.com",
      "path": "/",
      "expires": 1669287070.117333
    }
  ]
}
```

| Property  |  Type  | Description                                    |
|-----------|:------:|:-----------------------------------------------|
| status    | string | Status code received from the scraped web page |
| content   | string | Content from the scraped web page              |
| cookies   | array  | Response cookies from the scraped web page     |

### Error response

```json
{
  "name": "TimeoutError",
  "message": "Waiting for selector `.price` failed: Waiting failed: 30000ms exceeded"
}
```

### Responses status codes

| Code | Description                                         |
|:----:|:----------------------------------------------------|
| 200  | Successful                                          |
| 400  | Wrong request format                                |
| 404  | Error at execution. Client-side processing required |
