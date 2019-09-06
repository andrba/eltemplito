# El Templito

El Templito is an AWS Lambda driven templating service. It takes a `.docx` template file with `MailMerge` fields in it, replaces the fields with the provided values and generates a `PDF` file from the rendered template.

<img width="1138" alt="Screen Shot 2019-09-06 at 11 11 44 pm" src="https://user-images.githubusercontent.com/2174682/64430504-c14e1780-d0fb-11e9-9529-0acffe5f9160.png">

The Document Processing Unit is based on two Lambda functions orchestrated by a Dispatchr function:

1. Renderer. Based on [Sablon](https://github.com/senny/sablon)
2. PDF Generator. Based on LibreOffice

## Building

```
# Build Functions
rake build

# Build Layers
rake build_layers
```

## Deploying

```
# Deploy
rake deploy[stack-name,environment,s3_bucket_name]
```

## Testing

```
sam local start-api --env-vars .env.json
sam local invoke --event spec/fixtures/events/renderer_event.json --env-vars .env.json --skip-pull-image --region ap-southeast-2 RendererLambdaFunction
```
