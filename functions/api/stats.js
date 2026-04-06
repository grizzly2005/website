export async function onRequestGet(context) {
    const url = "https://ben-browser-tops-chess.trycloudflare.com/widget-stats";
    try {
        const response = await fetch(url);
        if (!response.ok) throw new Error("status " + response.status);
        const data = await response.json();
        return new Response(JSON.stringify(data), {
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "public, max-age=60",
            },
        });
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message, url: url }), {
            status: 502,
            headers: { "Content-Type": "application/json" },
        });
    }
}