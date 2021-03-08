# Define custom function directory
ARG FUNCTION_DIR="/function"

FROM python:3.8-buster as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    g++ \
    make \
    cmake \
    zip \
    unzip \
    gcc \
    libc-dev \
    libxslt-dev \
    libxml2-dev \
    libffi-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libgtk2.0-dev \
    libcurl4-openssl-dev

# Copy function code
RUN mkdir -p ${FUNCTION_DIR}

# Install the function's dependencies
RUN pip install \
    --target ${FUNCTION_DIR} \
    awslambdaric \
    boto3 \
    redis \
    httplib2 \
    requests \
    numpy \
    scipy \
    pandas \
    pika==0.13.1 \
    kafka-python \
    cloudpickle \
    ps-mem \
    tblib \
    opencv-python \
    torch \
    torchvision



FROM python:3.8-buster

ENV MODEL_URL http://moments.csail.mit.edu/moments_models/moments_RGB_resnet50_imagenetpretrained.pth.tar

RUN wget ${MODEL_URL} -o /tmp/model_weights

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-cache search linux-headers-generic

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Add Lithops
RUN mkdir lithops
COPY lithops_lambda.zip ${FUNCTION_DIR}
RUN unzip lithops_lambda.zip && rm lithops_lambda.zip

# Put your dependencies here, using RUN pip install... or RUN apt install...

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "__main__.lambda_handler" ]