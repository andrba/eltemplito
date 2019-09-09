# El Templito

<img width="1070" alt="Screen Shot 2019-09-09 at 1 53 18 pm" src="https://user-images.githubusercontent.com/2174682/64502382-3f333e00-d309-11e9-932e-7a1b4d77ffb2.png">

El Templito is an AWS Lambda driven templating service. It consists of `RenderTemplate` and `GeneratePdf` document processing components that can work either independently or in a combination, depending on the request parameters. See [API documentation](#api-documentation)

The Document Processing Unit demonstrates how by replacing AWS Step Functions with SNS-Lambda and sacrificing the reliability when it's acceptable, it is possible to reduce the cost of state transitioning by 62 times.

### RenderTemplate

Given a `docx` template file with optional `MailMerge` fields in it, it replaces the fields with values from a `merge_fields` parameter and saves the rendered `docx` document.

Template rendering is based on [Sablon](https://github.com/senny/sablon)

### GeneratePdf

Given an office document, e.g. `docx` or `xlsx` and `output_format=pdf`, it converts the document into a `pdf` format and saves the `pdf` file.

PDF generation is based on [LibreOffice](https://github.com/LibreOffice/core)

## API documentation

https://app.swaggerhub.com/apis-docs/eltemplito/eltemplito/1.0.0

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

## Development and Testing

Check out [events](https://github.com/andrba/eltemplito/tree/master/spec/fixtures/events) that are passed to lambda functions.

```
sam local start-api --env-vars .env.json

# ListenDocumentStreamFunction - handling new requests (DynamoDB Insert operation)
sam local invoke --event spec/fixtures/events/listen_document_stream_insert.json --env-vars .env.json ListenDocumentStreamFunction

# ListenDocumentStreamFunction - handling finished or failed requests (DynamoDB Modify operation)
sam local invoke --event spec/fixtures/events/listen_document_stream_modify.json --env-vars .env.json ListenDocumentStreamFunction

# DispatchrFunction - handling StateChanged event with a non-empty pipeline
sam local invoke --event spec/fixtures/events/dispatchr_not_empty_pipeline.json --env-vars .env.json DispatchrFunction

# DispatchrFunction - handling StateChanged event with an empty pipeline
sam local invoke --event spec/fixtures/events/dispatchr_empty_pipeline.json --env-vars .env.json DispatchrFunction

# RenderTemplateFunction
sam local invoke --event spec/fixtures/events/render_template.json --env-vars .env.json RenderTemplateFunction

# GeneratePdfFunction
sam local invoke --event spec/fixtures/events/generate_pdf.json --env-vars .env.json GeneratePdfFunction
```
