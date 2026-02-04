# zotxt Zotero 7/8 Compatibility Fixes

## Summary
Successfully ported zotxt from Zotero 6 to Zotero 7/8. The plugin now works correctly with the search endpoint returning results instantly.

## Version: 8.0.11

## Issues Fixed

### 1. **Missing Services Global** (v8.0.1)
**Problem:** `Services.scriptloader` was used but `Services` wasn't declared as a global variable.

**Fix:** Added `Services` to global declarations in bootstrap.js:
```javascript
/* global Components, Services, Set, ... */
```

### 2. **Deprecated Promise API** (v8.0.3)
**Problem:** Zotero 7 removed the Bluebird Promise library. `zotero.Promise.map()` and `zotero.Promise.filter()` no longer exist.

**Fix:** Replaced with native JavaScript:
```javascript
// Before:
zotero.Promise.map(items, (item) => {...})
zotero.Promise.filter(items, (item) => {...})

// After:
Promise.all(items.map((item) => {...}))
Promise.resolve(items.filter((item) => {...}))
```

### 3. **Mixed Promise Returns** (v8.0.4)
**Problem:** `getItemOrParent()` returned a promise sometimes and a plain value other times, breaking `Promise.all()`.

**Fix:** Made it always return a promise:
```javascript
// Before:
return item;

// After:
return Promise.resolve(item);
```

### 4. **Item Loading Changed** (v8.0.7)
**Problem:** `item.loadAllData()` no longer works properly in Zotero 7+.

**Fix:** Items now load data on-demand, so we skip unnecessary loading:
```javascript
function ensureLoaded(items, zotero) {
    return Promise.resolve(items);
}
```

### 5. **Translator System Broken** (v8.0.6)
**Problem:** The Easy Key translator wasn't being registered properly in Zotero 7+.

**Fix:** Generate easy keys directly without using the translator system:
```javascript
function generateEasyKey(item) {
    let year = item.getField('date').match(/[0-9]{4}/)?.[0] || '';
    let author = item.getCreators()[0]?.lastName || 'Anonymous';
    let title = item.getField('title');
    let titleWord = title.split(/\W+/).filter(w => w.length > 1)[0] || 'unknown';
    return '@' + author.toLowerCase() + ':' + year + titleWord.toLowerCase();
}
```

### 6. **Async Endpoint Handling** (v8.0.11) ⭐ **KEY FIX**
**Problem:** Zotero 7's HTTP server wasn't properly handling promise-returning endpoints.

**Fix:** Explicitly wrapped all async endpoints with async/await:
```javascript
function makeAsyncEndpoint(fn) {
    return async function(options) {
        try {
            let result = await fn(options);
            return result;
        } catch (e) {
            Zotero.debug('zotxt: endpoint error: ' + e);
            throw e;
        }
    };
}

// Usage:
'search': {
    supportedMethods: ['GET'],
    supportedDataType: ['application/x-www-form-urlencoded'],
    init: makeAsyncEndpoint(handleErrors(searchEndpoint))
}
```

## Testing

### Working Endpoints
```bash
# Version check
curl "http://127.0.0.1:23119/zotxt/version"
# Returns: {"version": "8.0.11"}

# Search with easy keys
curl "http://127.0.0.1:23119/zotxt/search?q=faria&format=easykey"
# Returns: ["@faria:2022differentiable","@faria:2024quest","@faria:sample"]

# Get item by key
curl "http://127.0.0.1:23119/zotxt/items?key=ABC123&format=easykey"
```

## Installation Instructions

1. **Remove old version completely:**
   ```bash
   rm -rf ~/Library/Application\ Support/Zotero/Profiles/*/extensions/zotxt@e6h.org*
   rm -rf ~/Library/Application\ Support/Zotero/Profiles/*/startupCache
   ```

2. **Install new version:**
   - Start Zotero
   - Tools → Add-ons → Gear icon → Install Add-on From File
   - Select `zotxt-8.0.11.xpi`
   - Restart Zotero

## Key Takeaways for Zotero 7 Plugin Development

1. **Always use `async/await`** for endpoints that return promises
2. **Native JavaScript promises only** - Bluebird is gone
3. **Items load on-demand** - don't try to preload data
4. **Services must be declared** in global comments
5. **Translators may not work** - consider direct implementation for simple formats

## Files Modified

- `extension/bootstrap.js` - Main endpoint logic and async wrappers
- `extension/core.js` - Promise API updates, item loading
- `extension/manifest.json` - Version bump to 8.0.11
- `update.json` - Added 8.0.11 release entry

## Credits

Original plugin by Erik Hetzner
Zotero 7/8 port fixes by collaborative debugging
