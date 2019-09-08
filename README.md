# El Templito

El Templito is an AWS Lambda driven templating service. It performs the following operations:

1. Given a `.docx` template file with optional `MailMerge` fields in it, replace the fields with values from a `merge_fields` parameter and save the result as `.docx` document.
2. Given an office document, e.g. `.docx` or `.xlsx`, convert the document into a `.pdf` format.
3. A combination of the first and the second operation.

## Architecture

<img width="1138" alt="Screen Shot 2019-09-06 at 11 11 44 pm" src="https://user-images.githubusercontent.com/2174682/64430504-c14e1780-d0fb-11e9-9529-0acffe5f9160.png">

### API documentation

https://app.swaggerhub.com/apis-docs/eltemplito/eltemplito/1.0.0


### Dependencies

Framework: [SAM](https://aws.amazon.com/serverless/sam)

Template rendering is based on [Sablon](https://github.com/senny/sablon)
PDF generation is based on [LibreOffice](https://github.com/LibreOffice/core)

## Building

```
# Build Functions
rake build

# Build Layers
rake build_layers

# Build a specific layer
rake build_layers[shared]
```

## Deploying

```
# Deploy
rake deploy[stack-name,environment,s3_bucket_name]
```

## Testing

```
sam local start-api --env-vars .env.json
sam local invoke --event spec/fixtures/events/renderer_event.json --env-vars .env.json RendererLambdaFunction
sam local invoke --event spec/fixtures/events/listen_document_stream_insert.json --env-vars .env.json ListenDocumentStreamFunction
```
