"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pubsubFunction = void 0;
const functions_framework_1 = require("@google-cloud/functions-framework");
const pubsub_1 = require("@google-cloud/pubsub");
const pubsub = new pubsub_1.PubSub();
async function handler(req, res) {
    const { path, method } = req;
    if (req.headers["events-secret"] !== process.env.EVENTS_FUNCTION_SECRET)
        return res.status(401).send("Unauthorized");
    if (method !== "POST") {
        return res.status(405).send(`Method ${method} not allowed`);
    }
    const topicName = path.substring(1); // remove leading slash
    const event = req.body.event;
    const attributes = {
        operation: event?.op,
    };
    const diff = {};
    try {
        if (event.data) {
            const { old, new: newData } = event.data;
            if (attributes.operation === "UPDATE") {
                for (const key in newData) {
                    if (newData[key] !== old[key]) {
                        attributes[key] = key;
                        diff[key] = { old: old[key], new: newData[key] };
                    }
                }
            }
            //   if (
            //     (attributes.operation === "INSERT" ||
            //       attributes.operation === "UPDATE") &&
            //     newData.tenant_id
            //   ) {
            //     attributes["tenant_id"] = newData.tenant_id;
            //   } else if (attributes.operation === "DELETE" && old.tenant_id) {
            //     attributes["tenant_id"] = old.tenant_id;
            //   }
            const message = JSON.stringify({ ...req.body, diff });
            const dataBuffer = Buffer.from(message);
            await pubsub
                .topic(topicName)
                .publishMessage({ attributes, data: dataBuffer });
            return res.status(200).send(`Message published to topic: ${topicName}`);
        }
        else {
            return res.status(200).send(`No data to publish`);
        }
    }
    catch (error) {
        console.error(`Error publishing message to topic ${topicName}: ${error}`);
        res
            .status(500)
            .send(`Error publishing message to topic ${topicName}: ${error}`);
    }
}
exports.pubsubFunction = (0, functions_framework_1.http)("pubsubFunction", handler);
