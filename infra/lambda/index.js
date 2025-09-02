'use strict';

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const uri = request.uri;

  console.log(
    'Incoming request:',
    JSON.stringify({
      uri,
      method: request.method,
      headers: request.headers,
    })
  );

  const albDns = 'micro-url-alb-2045249805.eu-central-1.elb.amazonaws.com';
  const s3Bucket = 'murl.pw-frontend.s3.eu-central-1.amazonaws.com';

  // /shorten → ALB
  if (uri.startsWith('/shorten')) {
    console.log('Routing → Shortening Service (ALB)');
    request.origin = {
      custom: {
        domainName: albDns,
        port: 80,
        protocol: 'http',
        readTimeout: 30,
        keepaliveTimeout: 5,
        sslProtocols: ['TLSv1.2'],
      },
    };
    request.headers['host'] = [{ key: 'host', value: albDns }];
    return request;
  }

  // slug → ALB
  const parts = uri.split('/').filter(Boolean);
  if (parts.length === 1 && !parts[0].includes('.')) {
    console.log('Routing → Forwarding Service (ALB)');
    request.origin = {
      custom: {
        domainName: albDns,
        port: 80,
        protocol: 'http',
        readTimeout: 30,
        keepaliveTimeout: 5,
        sslProtocols: ['TLSv1.2'],
      },
    };
    request.headers['host'] = [{ key: 'host', value: albDns }];
    return request;
  }

  // Default → S3
  console.log('Routing → S3 Frontend');
  request.origin = {
    s3: {
      domainName: s3Bucket,
      region: 'eu-central-1',
      authMethod: 'none',
    },
  };
  request.headers['host'] = [{ key: 'host', value: s3Bucket }];
  return request;
};
