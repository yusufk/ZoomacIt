# AI Snip

AI Snip adds image analysis to [Snip](/usage/snip). After you take a snip, right-click the thumbnail to extract text, translate it, find objects, or crop to the main subject.

AI features use Google's Gemini API. They are off until you add your own API key.

## Setup

1. Get a free key at [Google AI Studio](https://aistudio.google.com/apikey).
2. Open **ZoomacIt Settings → General**.
3. Turn on **Enable AI (requires Gemini API key)**.
4. Paste the key into **Gemini API Key**.
5. Pick a model. The default is **Gemini Flash (Latest)**.

Until AI is enabled and a key is set, the AI menu items are greyed out.

## Usage

1. Press **⌃6** (or **⌃⇧6**) and drag to select a region.
2. A thumbnail of the snip appears.
3. **Right-click** the thumbnail.
4. Choose an action from the menu.

## Actions

| Action | What it does | Result |
|---|---|---|
| Extract Text | Reads all visible text in the snip | Text is copied to the clipboard |
| Translate Text | Reads the text and translates it to English | Translation is copied to the clipboard |
| Search Text | Reads the text, then searches Google for it | Opens your browser with the results |
| Image Search | Opens Google Lens | Image is copied; paste it into Lens |
| Find Objects | Detects objects and their positions | Object list (JSON with bounding boxes) is copied to the clipboard |
| Smart Reframe | Finds the main subject and crops to it | Cropped image is copied to the clipboard |
| Copy Image | Copies the snip as an image | Image is copied; the thumbnail closes |

A dialog shows **Analyzing...** while the request runs, then a short confirmation of the result.

## Settings

| Setting | Description | Default |
|---|---|---|
| Enable AI | Turns the AI menu items on | Off |
| Gemini API Key | Your key from Google AI Studio | Empty |
| Model | Which Gemini model to use | Gemini Flash (Latest) |

Available models: Gemini Flash (Latest), Gemini 2.0 Flash, Gemini 2.0 Flash-Lite, Gemini 2.5 Flash, Gemini 2.5 Pro.

## Privacy

When you run an AI action, ZoomacIt sends that snip to Google's Gemini API using your key. Nothing is sent until you choose an action. Snips you only copy or save are never uploaded.

Image Search does not call Gemini. It copies the snip and opens Google Lens, where you paste it yourself.

## Rate limits

The free Gemini tier has usage limits. If the selected model returns a rate-limit error, ZoomacIt retries once with Gemini 2.0 Flash-Lite. If that is also limited, you see "Rate limited" and can try again in a minute.
