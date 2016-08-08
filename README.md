# particle-firebase-proxy

_A proxy/reverse-proxy for Firebase Realtime Database events -> Particle.io cloud events_

### Introduction

_TL;DR - Now you can use Firebase Realtime Database events with Particle.io devices._

Particle.io Webhooks can retrieve static pages, but can't subscribe to Server Sent Event streams, such as event streams (that used to be) provided by [Firebase database events](https://firebase.google.com/docs/database/web/retrieve-data#listen_for_events). 
Furthermore, Firebase v3+ requires authentication token generation that doesn't work well for IoT devices. 

This proxy/reverse-proxy can be configured to work with a Firebase app via a Service Account. Particle.io devices can push or pull data via REST webhooks, as well as subscribe to the proxy. Database events are published to the subscribing event stream.

### How To Use REST Calls

Once you've set up the proxy/reverse-proxy somewhere, you can make REST calls to the 
proxy as if it were the Firebase database itself. It more or less conforms to the the documentation in the [REST Firebase Realtime Database docs](https://firebase.google.com/docs/reference/rest/database/). However, you must add `device_id` and `particle_token` query parameters to your REST call. The `particle_token` is validated before the database is accessed, and the `device_id` is translated to the Firebase database security rules `auth.uid` claim.

```
curl https://myproxy:9000/my/data?device_id=0123456789&particle_token=0123456789abcdef -X PUT -H "Content: application/json" -d '{ "key" : "value" }'
```

### How To Subscribe To Realtime Database Events

Make a REST call to the database location which you would like monitored for events. Add an additional query parameter `event_type` that corresponds to the event types listed in the documentation for [Firebase database events](https://firebase.google.com/docs/database/web/retrieve-data#listen_for_events) -- `value`, `child_added`, 
`child_changed`, `child_removed`, `child_moved`.

```
curl https://myproxy:9000/my/data?device_id=0123456789&particle_token=0123456789abcdef&event_type=value -X GET
```

The proxy will respond with a `(200) OK` if it was successful, or an error message. After that, you should see events being published with the name corresponding to your `event_type` parameter. The data payload will be:

```
{
	"key" : "snapshot.key",
	"val" : "snapshot.val()",
}
```

If an error is ever generated by the event subscription (for exmaple, if permissions changed and your subscription was cancelled) a `cancel` event will be generated with error data in the payload.

The reverse-proxy will only store *one* event subscription at a time. A subsequent event subscription will cancel the previous one. Regular REST calls without `event_type` will not cancel any existing subscriptions.

### Setup

- Installed [NodeJS](http://nodejs.org) and a `git` client.
- Clone this repo with

	```
	git clone https://github.com/jychuah/particle-firebase-proxy
	```

- Install the required modules with

	```
	npm install
	```
	
- Setup a Firebase App and some database access rules!
- Setup a Google Service Account and download the credentials .json. Instructions for creating a service account for your Firebase App can be found [here](https://firebase.google.com/docs/server/setup), under the _Add Firebase to your app_ heading. Save this file in the root of your clone of this repo.
- Configure `DATABASE` and `SERVICEACCOUNTFILE` environment variables.
	- `DATABASE` should be set to your Firebase database's URL. For example, `http://myfirebase.firebaseio.com`
	- `SERVICEACCOUNTFILE` should be set to your service account.json file. For example, `serviceAccount.json`
	- If you are using [Node Foreman](https://github.com/strongloop/node-foreman), you may simply edit the [`.env`](./env) file.
- If you are testing the reverse proxy locally, you can launch it with `npm start`. If you have Node Forman installed, you can run `nf start` and it will grab all the environment variables automatically.
- Deploy it somewhere.

### Testing

Two scripts are available for testing your proxy with `curl`. Fill in the necessary variables in the scripts to run them.

The [`./tests/test_rest.sh`](./tests/test_rest.sh) script is included to test non-EventSource REST calls. You should receive an `OK` in the command line for `PUT` and `DELETE` calls, a keyname for any `POST` calls and JSON data for any `GET` calls.

The ['./tests/test_events.sh'] script is included to test EventSource GET calls. You should receive an `OK` in the command line, with any events appearing in your [Particle.io Console](http://console.particle.io).

### Setting Up A Webhook

It's a good idea to let your Particle.io device interact with the proxy using Webhooks. [`./examples/webhook.json.example`](./examples/webhook.json.example) has been included to illustrate a Webhook that passes the necessary data to your proxy to subscribe to realtime database events. That way, you can simply call...

```
Particle.subscribe("value", handlerFunction);
Particle.publish("valueSub");
```

...from within your device firmware.

_Access Token Security_

When you setup your Webhook, you will want to [create a non-expiring Particle.io access token](https://docs.particle.io/reference/api/#generate-an-access-token) and store it in your Webhook. When you have it stored in a Webhook, the token is transmitted over HTTPS to the reverse proxy. The reverse proxy does not save the access token and uses it only to publish events back to the requesting device.

### Firebase Database Security

It's a good idea to [secure access to any Firebase Database paths](https://firebase.google.com/docs/database/security/) that you will access using the reverse proxy. The reverse proxy authenticates using your Service Account, with `auth.uid` set to your `device_id` query parameter. The provided [`./examples/database.rules.json.example`](./examples/database.rules.json.example) demonstrates how to secure read access using `auth.uid`, limiting any authenticated device to reading its own `/device/device_id` path.

### Deploying to Heroku

I tested this reverse proxy on [Heroku](http://heroku.com). To setup Heroku, make sure you have command line `git`, the [Heroku Toolbelt](https://toolbelt.heroku.com/), and a verified account. To deploy this reverse proxy, do the following:

- Clone this repo

	```
	git clone https://github.com/jychuah/particle-firebase-proxy
	cd particle-firebase-proxy
	```

- Save your `serviceAccount.json` file in the root of your clone. Add it to your repo with:

	```
	git add serviceAccount.json
	git commit -m "Added serviceAccount"
	```

- Edit the [`.env`](./env) file to point to your `serviceAccount.json` file and your Firebase database
- Create a Heroku dyno and make a note of the endpoint. (Heroku services always run on port 80, so your `PORT` variable will be ignored.)

	```
	heroku login
	heroku create
	```
	
- Send your environment variables to your Heroku dyno. You can use the included script.

	```
	./heroku_config.sh
	```

- Push it to Heroku

	```
	git push heroku master
	```
	
- Check to see if it's running with

	```
	heroku logs --tail
	```