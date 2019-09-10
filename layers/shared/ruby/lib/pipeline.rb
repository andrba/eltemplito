module Pipeline
  RENDER_DOCUMENT = 'RENDER_TEMPLATE_FUNCTION'
  GENERATE_PDF    = 'GENERATE_PDF_FUNCTION'

  module_function def build_from_request(request)
    [
      *(RENDER_DOCUMENT if request['merge_fields'].any?),
      *(GENERATE_PDF    if request['output_format'] == 'pdf'),
    ]
  end
end
