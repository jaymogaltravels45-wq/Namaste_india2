// ─── WhatsApp OTP via Meta Cloud API ───────────────────────────────────────
// Sends the OTP as a WhatsApp *Authentication template* message.
// No DLT registration needed — WhatsApp templates are approved by Meta,
// not by Indian telecom DLT.
//
// Setup (one-time, Meta developer account):
//   1. developers.facebook.com → Create App (Business) → add "WhatsApp" product
//   2. WhatsApp → API Setup → add & verify a phone number → note the
//      Phone Number ID (WHATSAPP_PHONE_NUMBER_ID)
//   3. Business Manager → System User → permanent token with the
//      whatsapp_business_messaging permission (WHATSAPP_ACCESS_TOKEN)
//   4. WhatsApp Manager → Message Templates → create an *Authentication*
//      template (e.g. name "namaste_otp") → wait for Meta approval
//      (usually a few hours) → WHATSAPP_TEMPLATE_NAME
//
// API: POST https://graph.facebook.com/v21.0/{phone-number-id}/messages
//   Headers: { Authorization: "Bearer <token>", Content-Type: "application/json" }
//   Body: template message with the OTP as the body parameter (+ copy-code
//         button parameter, which Meta's auth templates support).
// Success: { messages: [{ id: "wamid...." }], messaging_product: "whatsapp" }
// Failure: { error: { message, code, ... } } (HTTP 4xx)

const axios = require("axios");

const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const ACCESS_TOKEN    = process.env.WHATSAPP_ACCESS_TOKEN;
const TEMPLATE_NAME   = process.env.WHATSAPP_TEMPLATE_NAME || "namaste_otp";
const TEMPLATE_LANG   = process.env.WHATSAPP_TEMPLATE_LANG || "en";

const configured = () => Boolean(PHONE_NUMBER_ID && ACCESS_TOKEN);

/**
 * Send `otp` to `number10` (plain 10-digit Indian mobile) over WhatsApp.
 * @returns {Promise<string|null>} the WhatsApp message id (wamid) on success
 * @throws when not configured or Meta rejects the request
 */
async function sendOtpViaWhatsApp(number10, otp) {
  if (!configured()) {
    throw new Error("WHATSAPP_PHONE_NUMBER_ID / WHATSAPP_ACCESS_TOKEN not configured");
  }

  const to = "91" + String(number10).replace(/\D/g, "").slice(-10);

  const { status, data } = await axios.post(
    `https://graph.facebook.com/v21.0/${PHONE_NUMBER_ID}/messages`,
    {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "template",
      template: {
        name: TEMPLATE_NAME,
        language: { code: TEMPLATE_LANG },
        components: [
          {
            type: "body",
            parameters: [{ type: "text", text: String(otp) }],
          },
          {
            // Meta authentication templates support a copy-code button;
            // passing the code here enables one-tap autofill on the phone.
            type: "button",
            sub_type: "url",
            index: "0",
            parameters: [{ type: "text", text: String(otp) }],
          },
        ],
      },
    },
    {
      headers: {
        Authorization: `Bearer ${ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      timeout: 30000,
    }
  );

  console.log("WhatsApp Cloud API response:", JSON.stringify(data));

  const wamid = data?.messages?.[0]?.id;
  if (status !== 200 || !wamid) {
    const metaErr = data?.error?.message || data?.error?.error_data?.details;
    throw new Error(metaErr || "WhatsApp API rejected the request");
  }
  return wamid;
}

module.exports = { sendOtpViaWhatsApp, whatsappConfigured: configured };
