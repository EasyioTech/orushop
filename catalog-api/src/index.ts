export interface Env {
	DB: D1Database;
}

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);
		const shopType = url.searchParams.get("type");
		const sku = url.searchParams.get("sku");
		const limit = Math.min(parseInt(url.searchParams.get("limit") || "100"), 500);
		const offset = Math.max(parseInt(url.searchParams.get("offset") || "0"), 0);

		// Route: POST /api/users/{userId}/request-deletion
		if (request.method === "POST" && url.pathname.match(/^\/api\/users\/[^/]+\/request-deletion$/)) {
			const pathParts = url.pathname.split("/");
			const userId = pathParts[3];

			try {
				const authHeader = request.headers.get("Authorization");
				if (!authHeader || !authHeader.startsWith("Bearer ")) {
					return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
				}

				const token = authHeader.substring(7);
				if (!token || token.length < 10) {
					return new Response(JSON.stringify({ error: "Invalid token format" }), { status: 401 });
				}

				const body = await request.json() as { userId: string; requestedAt: string };

				if (!body.userId || !body.requestedAt) {
					return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400 });
				}

				if (body.userId !== userId) {
					return new Response(JSON.stringify({ error: "User ID mismatch" }), { status: 400 });
				}

				// Queue data deletion job (store in DB for async processing)
				await env.DB.prepare(
					`INSERT INTO user_deletion_requests (user_id, requested_at, status)
					 VALUES (?, ?, 'pending')
					 ON CONFLICT(user_id) DO UPDATE SET status='pending', requested_at=?`
				).bind(userId, body.requestedAt, body.requestedAt).run();

				return new Response(JSON.stringify({
					success: true,
					message: "Data deletion request submitted",
					userId
				}), {
					status: 200,
					headers: { "content-type": "application/json" }
				});
			} catch (e: any) {
				console.error("Data deletion request error:", e);
				return new Response(JSON.stringify({ error: "Internal server error" }), { status: 500 });
			}
		}

		// Route: /catalog?sku=12345&type=medical
		if (url.pathname === "/catalog" && sku && shopType) {
			const tableName = getTableName(shopType);
			try {
				if (!tableName) {
					return new Response(JSON.stringify({ error: "Invalid store type" }), { status: 400 });
				}

				const { results } = await env.DB.prepare(
					`SELECT * FROM ${tableName} WHERE LOWER(barcode) = LOWER(?) OR LOWER(parent_sku) = LOWER(?) LIMIT 1`
				).bind(sku, sku).all();

				return new Response(JSON.stringify({ success: true, data: results || [], count: results?.length || 0 }), {
					headers: {
						"content-type": "application/json",
						"Access-Control-Allow-Origin": "*"
					},
				});
			} catch (e: any) {
				return new Response(JSON.stringify({ error: e.message }), { status: 500 });
			}
		}

		// Route: /catalog?type=medical
		if (url.pathname === "/catalog" && shopType) {
			const tableName = getTableName(shopType);
			try {
				if (!tableName) {
					return new Response(JSON.stringify({ error: "Invalid store type" }), { status: 400 });
				}

				const { results } = await env.DB.prepare(
					`SELECT * FROM ${tableName} ORDER BY name ASC LIMIT ? OFFSET ?`
				).bind(limit, offset).all();

				const { results: countResult } = await env.DB.prepare(
					`SELECT COUNT(*) as total FROM ${tableName}`
				).all();

				const total = (countResult?.[0]?.total as number) || 0;

				return new Response(JSON.stringify({
					success: true,
					data: results || [],
					count: results?.length || 0,
					total,
					limit,
					offset
				}), {
					headers: {
						"content-type": "application/json",
						"Access-Control-Allow-Origin": "*"
					},
				});
			} catch (e: any) {
				return new Response(JSON.stringify({ error: e.message }), { status: 500 });
			}
		}

		return new Response(JSON.stringify({ error: "Invalid request" }), { status: 400 });
	},
};

function getTableName(type: string): string | null {
	const mapping: Record<string, string> = {
		'medical': 'catalog_medical',
		'grocery': 'catalog_kirana_stores',
		'bakery': 'catalog_kirana_stores',
		'electronics': 'catalog_electronics_stores',
		'mobile': 'catalog_electronics_stores',
		'hardware': 'catalog_electronics_stores',
		'clothing': 'catalog_clothing_boutiques',
		'footwear': 'catalog_footwear_stores',
		'stationery': 'catalog_stationery_shops',
		'toys': 'catalog_toy_stores',
		'pets': 'catalog_pet_supply_stores',
		'home': 'catalog_home_decor_stores',
		'cosmetics': 'catalog_cosmetics_stores',
		'restaurant': 'catalog_other',
		'other': 'catalog_other'
	};

	return mapping[type.toLowerCase()] || null;
}

