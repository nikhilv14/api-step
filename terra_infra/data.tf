data "template_file" prisma_api_swagger{
  template = "${file("SwaggerForAPIGateway.yml")}"
}

