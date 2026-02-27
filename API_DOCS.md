# ResQNet — Additional Endpoints

Changes made after initial API_DOCS.md was written.

---

## 1. Social Reporting (Mobile App)
**Router:** `backend/app/routers/social.py`

Lets citizens interact with existing events - confirm sightings, post quick observations, and browse a community feed.

---

### POST `/social/events/{event_id}/confirm`
One-tap "I can see this too" on an existing event. Validates user is within 10km. Counts as a `social` signal in confidence scoring.

**Request**
```json
{
  "latitude": 12.9360,
  "longitude": 77.6250,
  "user_id": "optional-uuid"
}
```

**Response `200`**
```json
{
  "message": "Confirmation recorded. Thank you.",
  "event_id": "14c91cff-d7d0-4851-a79e-97cc3d7faa07",
  "new_confidence": 32.0
}
```

**Response `400`** - user too far
```json
{ "detail": "You are 14.2km from this event. Confirmations must be within 10km." }
```

---

### POST `/social/observe`
Quick free-text observation. Lighter than a full emergency report - no people count or injury fields. Auto geo-clusters into nearest event.

**Request**
```json
{
  "latitude": 12.9352,
  "longitude": 77.6245,
  "disaster_type": "flood",
  "observation": "Water above ankle level on 5th main road",
  "user_id": "optional-uuid"
}
```

**Response `200`**
```json
{
  "message": "Observation posted.",
  "report_id": "c1ee19b4-95c5-43d8-8d7e-fff6c4452086",
  "event_id": "14c91cff-d7d0-4851-a79e-97cc3d7faa07",
  "confidence": 32.0
}
```

---

### GET `/social/feed`
Community feed for the mobile app home screen. Active events near the user with distance and confirmation count. Recommended over `GET /events/nearby` for the app.

**Query params**
| Param | Type | Default | Notes |
|-------|------|---------|-------|
| lat | float | required | |
| lng | float | required | |
| radius_km | float | `10.0` | |

**Example:** `GET /social/feed?lat=12.93&lng=77.62&radius_km=5`

**Response `200`**
```json
[
  {
    "id": "14c91cff-d7d0-4851-a79e-97cc3d7faa07",
    "type": "flood",
    "latitude": 12.9352,
    "longitude": 77.6245,
    "confidence": 55.0,
    "severity": "medium",
    "active": true,
    "created_at": "2026-02-27T05:23:28.833172+00:00",
    "distance_km": 0.82,
    "confirmations": 7
  }
]
```

---

### GET `/social/events/{event_id}/confirmations`
Confirmation count and individual confirmation locations for an event detail page.

**Response `200`**
```json
{
  "event_id": "14c91cff-d7d0-4851-a79e-97cc3d7faa07",
  "confirmation_count": 7,
  "confirmations": [
    {
      "id": "aabb1122-...",
      "latitude": 12.9360,
      "longitude": 77.6250,
      "created_at": "2026-02-27T05:30:00.000000+00:00"
    }
  ]
}
```

---

## 2. News
**Router:** `backend/app/routers/news.py`
**Scraper:** `backend/scrape_news.py`
**Data file:** `backend/data/news.json`

News is scraped manually by running a script. The endpoint only reads the saved file - no scraping at runtime.

### How to update news
```bash
cd backend
python scrape_news.py
```
Scrapes Google News RSS across 6 disaster categories (flood, earthquake, cyclone, landslide, wildfire, disaster relief) filtered for India. Saves up to 30 articles to `data/news.json`. Re-run whenever you want fresh articles.

---

### GET `/news`
Returns all cached news articles.

**Query params**
| Param | Type | Notes |
|-------|------|-------|
| disaster_type | string | Filter by `flood`, `earthquake`, `fire`, `landslide`, `other` |

**Example:** `GET /news?disaster_type=earthquake`

**Response `200`**
```json
{
  "articles": [
    {
      "title": "Strong Earthquake Tremors Felt In Kolkata, Offices Evacuated",
      "source": "NDTV",
      "url": "https://...",
      "summary": "Tremors were felt across Kolkata on Friday afternoon...",
      "published": "Fri, 27 Feb 2026 08:00:00 GMT",
      "disaster_type": "earthquake",
      "query": "earthquake India"
    }
  ],
  "total": 9,
  "scraped_at": "2026-02-27T09:24:50.498297+00:00"
}
```

**Response `404`** - scraper hasn't been run yet
```json
{ "detail": "No news data found. Run: python scrape_news.py" }
```
