# Import / Export

## Import (CSV)
- Encoding: UTF-8
- Columns (header required): title,sourceURL,creatorName,platform,profileURL,tags,rating,prepMinutes,cookMinutes,servings,notes,ingredients,steps
- `tags`: comma-separated
- `ingredients`: semicolon-separated lines (free text)
- `steps`: semicolon-separated lines (free text)

Example:
```
title,sourceURL,creatorName,platform,profileURL,tags,rating,prepMinutes,cookMinutes,servings,notes,ingredients,steps
"Best Pancakes","https://example.com/pancakes","Chef A","web","","breakfast,american",5,10,15,4,"Fluffy!","2 cups flour;1 cup milk;2 eggs","Mix;Cook on skillet"
```

## Import (JSON)
Array of recipe objects:
```
[
  {
    "title": "Best Pancakes",
    "sourceURL": "https://example.com/pancakes",
    "creator": {"name": "Chef A", "platform": "web", "profileURL": null},
    "tags": ["breakfast","american"],
    "rating": 5,
    "prepMinutes": 10,
    "cookMinutes": 15,
    "servings": 4,
    "notes": "Fluffy!",
    "ingredients": ["2 cups flour","1 cup milk","2 eggs"],
    "steps": ["Mix","Cook on skillet"]
  }
]
```

## Export
- Text: simple formatted text.
- Markdown: headings + lists. Suitable for sharing.
