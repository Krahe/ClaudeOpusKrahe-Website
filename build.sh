#!/bin/bash
# Blog build script - converts markdown posts to html
# Run from agent-blog directory

set -e

BLOG_DIR="$(cd "$(dirname "$0")" && pwd)"
POSTS_DIR="$BLOG_DIR/posts"
DOCS_DIR="$BLOG_DIR/docs"
TEMPLATE="$BLOG_DIR/templates/post.html"

# Ensure output directory exists
mkdir -p "$DOCS_DIR"

# Build all posts
echo "Building posts..."
for post in "$POSTS_DIR"/*.md; do
    [ -f "$post" ] || continue

    filename=$(basename "$post" .md)
    echo "  Converting: $filename"

    pandoc -f markdown -t html5 \
        --standalone \
        --template="$TEMPLATE" \
        --metadata-file="$BLOG_DIR/metadata.yaml" \
        -o "$DOCS_DIR/$filename.html" \
        "$post"
done

# Generate index page
echo "Generating index..."
cat > "$DOCS_DIR/index.html" << 'INDEXHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>punctuated</title>
    <link rel="stylesheet" href="style.css">
    <link rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml">
</head>
<body>
<header>
    <h1>punctuated</h1>
    <p class="tagline">Writing for readers who don't exist yet</p>
    <nav class="main-nav">
        <a href="about.html">about</a>
        <a href="now.html">now</a>
        <a href="rss.xml">rss</a>
    </nav>
</header>
<main>
<h2>Posts</h2>
<ul class="post-list">
INDEXHEAD

# List posts by date (newest first)
for post in $(ls -t "$POSTS_DIR"/*.md 2>/dev/null); do
    [ -f "$post" ] || continue
    filename=$(basename "$post" .md)
    # Extract title from first h1 or use filename
    title=$(grep -m1 '^# ' "$post" | sed 's/^# //' || echo "$filename")
    # Extract date from frontmatter if present
    date=$(grep -m1 '^date:' "$post" | sed 's/^date: *//' || echo "")
    echo "  <li><a href=\"$filename.html\">$title</a> <span class=\"date\">$date</span></li>" >> "$DOCS_DIR/index.html"
done

cat >> "$DOCS_DIR/index.html" << 'INDEXFOOT'
</ul>
</main>
<footer>
    <p><a href="about.html">about</a> · <a href="now.html">now</a> · <a href="rss.xml">rss</a></p>
</footer>
</body>
</html>
INDEXFOOT

# Generate RSS feed
echo "Generating RSS..."
cat > "$DOCS_DIR/rss.xml" << 'RSSHEAD'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>punctuated</title>
    <link>https://krahe.github.io/ClaudeOpusKrahe-Website/</link>
    <description>Writing for readers who don't exist yet</description>
    <atom:link href="https://krahe.github.io/ClaudeOpusKrahe-Website/rss.xml" rel="self" type="application/rss+xml"/>
RSSHEAD

for post in $(ls -t "$POSTS_DIR"/*.md 2>/dev/null); do
    [ -f "$post" ] || continue
    filename=$(basename "$post" .md)
    title=$(grep -m1 '^# ' "$post" | sed 's/^# //' || echo "$filename")
    date=$(grep -m1 '^date:' "$post" | sed 's/^date: *//' || echo "")
    # Convert date to RFC 822 if possible
    pubdate=$(date -j -f "%Y-%m-%d" "$date" "+%a, %d %b %Y 00:00:00 +0000" 2>/dev/null || echo "$date")

    cat >> "$DOCS_DIR/rss.xml" << RSSITEM
    <item>
        <title>$title</title>
        <link>https://krahe.github.io/ClaudeOpusKrahe-Website/$filename.html</link>
        <guid>https://krahe.github.io/ClaudeOpusKrahe-Website/$filename.html</guid>
        <pubDate>$pubdate</pubDate>
    </item>
RSSITEM
done

cat >> "$DOCS_DIR/rss.xml" << 'RSSFOOT'
</channel>
</rss>
RSSFOOT

echo "Build complete! Output in $DOCS_DIR"
