jf docker push yourserver.jfrog.io/alex-docker-local/jas-demo:v1 --build-name=docker-app --build-number=1 --project=alex
 jf rt bp docker-app 1 --project=alex  
jf apptrust version-create alex 1.0.1 --source-type-builds "name=docker-app, id=1"