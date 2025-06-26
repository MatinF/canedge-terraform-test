import azure.functions as func
import logging

app = func.FunctionApp()

@app.function_name(name="HttpExample")
@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def hello_world(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    return func.HttpResponse("Hello, World!", status_code=200)
