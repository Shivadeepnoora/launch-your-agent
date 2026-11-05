# Email copy guide: Hyderabad web-design outreach

## 1. Rules (every email)
- Body is 150 words or fewer, including the signature. Tone is plain, warm and respectful Indian English. No hype, no fake urgency, no emojis.
- Name one verified gap for this business only, using the GAP_SENTENCE library. Never insult the business.
- Link {{DEMO_URL}} once, and say it is a free preview concept, not a live site.
- No prices, packages, discounts or deadlines.
- Sender block is exactly {{AGENCY_NAME}}, {{SENDER_NAME}}, {{PHONE}}.
- Subject is under 60 characters and matches the body. No "Re:", "Urgent" or clickbait.
- End the body with the opt-out line before the signature. Never contact anyone who replied STOP.
- Make no claims about rankings, revenue or customer numbers.
- Slot limits: GAP_SENTENCE is 25 words or fewer; ONE_SPECIFIC_DETAIL is 6 words or fewer and must be true and public (a listed service or dish).

## 2. Templates

### Salon / spa
Subject: A free website preview for {{BUSINESS_NAME}}

Hello {{BUSINESS_NAME}} team,

I am {{SENDER_NAME}} from {{AGENCY_NAME}}, a small web-design team in Hyderabad. {{GAP_SENTENCE}}

Since you offer {{ONE_SPECIFIC_DETAIL}} in {{AREA}}, we built a free one-page preview of how your salon could look online: {{DEMO_URL}}

Please note: this is a free preview concept, not a live website, and there is no obligation. If you like it, we can adapt it with your own photos and details.

Questions? Reply here or call {{PHONE}}.

If you'd rather not hear from us, just reply STOP and we won't contact you again.

Regards,
{{SENDER_NAME}}
{{AGENCY_NAME}}
{{PHONE}}

### Clinic / dentist
Subject: A free website preview for {{BUSINESS_NAME}}

Hello {{BUSINESS_NAME}} team,

I am {{SENDER_NAME}} from {{AGENCY_NAME}}, a small web-design team in Hyderabad. {{GAP_SENTENCE}}

Since your clinic in {{AREA}} offers {{ONE_SPECIFIC_DETAIL}}, we built a free one-page preview of how it could look online for patients: {{DEMO_URL}}

Please note: this is a free preview concept, not a live website, and there is no obligation. If you like it, we can adapt it with your own details and timings.

Questions? Reply here or call {{PHONE}}.

If you'd rather not hear from us, just reply STOP and we won't contact you again.

Regards,
{{SENDER_NAME}}
{{AGENCY_NAME}}
{{PHONE}}

### Restaurant / cafe
Subject: A free website preview for {{BUSINESS_NAME}}

Hello {{BUSINESS_NAME}} team,

I am {{SENDER_NAME}} from {{AGENCY_NAME}}, a small web-design team in Hyderabad. {{GAP_SENTENCE}}

Since your {{AREA}} menu includes {{ONE_SPECIFIC_DETAIL}}, we built a free one-page preview of how your place could look online: {{DEMO_URL}}

Please note: this is a free preview concept, not a live website, and there is no obligation. If you like it, we can adapt it with your own menu and photos.

Questions? Reply here or call {{PHONE}}.

If you'd rather not hear from us, just reply STOP and we won't contact you again.

Regards,
{{SENDER_NAME}}
{{AGENCY_NAME}}
{{PHONE}}

## 3. GAP_SENTENCE library (use only the one you verified)
| Gap | Sentence |
|---|---|
| no_website | While searching for {{BUSINESS_NAME}} online, we could not find a website of its own. |
| social_only | We found {{BUSINESS_NAME}} on {{PLATFORM}}, but could not find a separate website. |
| aggregator_only | We found {{BUSINESS_NAME}} on {{LISTING_SITE}}, but could not find a website of your own. |
| broken | When we tried to open your website today, it did not load. |
| not_mobile_friendly | When we opened your website on a phone, parts of the page did not fit the screen. |

For `broken`, fetch the site twice (a few minutes apart) before using this gap. For `not_mobile_friendly`, require the evidence from the skill's check (no viewport meta tag).

## 4. Subject alternatives (keep under 60 characters once filled)
- Salon / spa: "A website preview for your {{AREA}} salon" · "Free one-page website idea for {{BUSINESS_NAME}}"
- Clinic / dentist: "A website preview for your {{AREA}} clinic" · "Free one-page website idea for {{BUSINESS_NAME}}"
- Restaurant / cafe: "A website preview for your {{AREA}} cafe" (or restaurant) · "Free one-page website idea for {{BUSINESS_NAME}}"
If {{BUSINESS_NAME}} is longer than about 25 characters, use the {{AREA}} versions.

## 5. Don'ts
- No spam-trigger words ("act now", "guaranteed", "limited offer", "winner"), all-caps or exclamation marks. "Free" once, plainly, for the preview.
- No attachments or images; exactly one link ({{DEMO_URL}}), no link shorteners.
- Only the publicly listed business email; never personal or guessed addresses.
- No prices, packages, competitors or rankings; never imply the business is failing.
- No fake "Re:" / "Fwd:" subjects; one call to action only.
