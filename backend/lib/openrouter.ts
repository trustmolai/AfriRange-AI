import crypto from 'crypto';

// ===================================================================
// AfriRange AI — OpenRouter Client
// Handles AI reasoning for grazing intelligence with cost optimization
// ===================================================================

const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';

// Cost-efficient primary model with strong reasoning for agricultural data
export const PRIMARY_MODEL = 'meta-llama/llama-3.3-70b-instruct';
// Fallback model when primary is unavailable or rate-limited
export const FALLBACK_MODEL = 'google/gemini-2.0-flash-001';

export interface OpenRouterMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface OpenRouterResponse {
  choices: Array<{
    message: {
      content: string;
    };
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  model: string;
}

export interface TokenUsageRecord {
  endpoint: string;
  model: string;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  timestamp: Date;
  userId?: string;
}

// In-memory cache for AI responses to reduce token costs
const responseCache = new Map<string, { response: string; timestamp: Date }>();
const CACHE_TTL_MS = 1000 * 60 * 60; // 1 hour cache

/**
 * Generate cache key from prompt content
 */
function generateCacheKey(messages: OpenRouterMessage[], model: string): string {
  const content = messages.map(m => `${m.role}:${m.content}`).join('|');
  return crypto.createHash('sha256').update(`${model}:${content}`).digest('hex');
}

/**
 * Check if cached response is still valid
 */
function getCachedResponse(cacheKey: string): string | null {
  const cached = responseCache.get(cacheKey);
  if (!cached) return null;
  
  const age = Date.now() - cached.timestamp.getTime();
  if (age > CACHE_TTL_MS) {
    responseCache.delete(cacheKey);
    return null;
  }
  
  return cached.response;
}

/**
 * Store response in cache
 */
function setCachedResponse(cacheKey: string, response: string): void {
  responseCache.set(cacheKey, { response, timestamp: new Date() });
}

/**
 * Track token usage for billing and cost optimization
 */
export class TokenUsageTracker {
  private static records: TokenUsageRecord[] = [];
  private static readonly MAX_RECORDS = 1000;

  static record(record: TokenUsageRecord): void {
    this.records.push(record);
    if (this.records.length > this.MAX_RECORDS) {
      this.records = this.records.slice(-this.MAX_RECORDS);
    }
    console.log(`[Token Usage] ${record.endpoint}: ${record.totalTokens} tokens (${record.model})`);
  }

  static getTotalUsage(endpoint?: string): { promptTokens: number; completionTokens: number; totalTokens: number } {
    const records = endpoint 
      ? this.records.filter(r => r.endpoint === endpoint)
      : this.records;
    
    return records.reduce(
      (acc, r) => ({
        promptTokens: acc.promptTokens + r.promptTokens,
        completionTokens: acc.completionTokens + r.completionTokens,
        totalTokens: acc.totalTokens + r.totalTokens,
      }),
      { promptTokens: 0, completionTokens: 0, totalTokens: 0 }
    );
  }

  static getRecentUsage(minutes: number = 60): TokenUsageRecord[] {
    const cutoff = Date.now() - minutes * 60 * 1000;
    return this.records.filter(r => r.timestamp.getTime() > cutoff);
  }
}

/**
 * Make a request to OpenRouter with caching, retries, and fallback
 */
export async function callOpenRouter(
  messages: OpenRouterMessage[],
  options: {
    model?: string;
    temperature?: number;
    maxTokens?: number;
    useCache?: boolean;
    userId?: string;
    endpoint: string;
  } = { endpoint: 'grazing-engine' }
): Promise<{ content: string; model: string; usage: { promptTokens: number; completionTokens: number; totalTokens: number } }> {
  const {
    model = PRIMARY_MODEL,
    temperature = 0.3,
    maxTokens = 1024,
    useCache = true,
    userId,
    endpoint,
  } = options;

  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey || apiKey === 'sk-or-mock-key') {
    throw new Error('OpenRouter API key not configured. Set OPENROUTER_API_KEY environment variable.');
  }

  // Check cache first
  if (useCache) {
    const cacheKey = generateCacheKey(messages, model);
    const cached = getCachedResponse(cacheKey);
    if (cached) {
      console.log(`[OpenRouter Cache Hit] ${endpoint} (${model})`);
      return {
        content: cached,
        model,
        usage: { promptTokens: 0, completionTokens: 0, totalTokens: 0 },
      };
    }
  }

  // Try primary model, then fallback
  const modelsToTry = [model, FALLBACK_MODEL];
  let lastError: Error | null = null;

  for (const attemptModel of modelsToTry) {
    try {
      const response = await fetch(`${OPENROUTER_BASE_URL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://afrirange.ai',
          'X-Title': 'AfriRange AI Grazing Intelligence',
        },
        body: JSON.stringify({
          model: attemptModel,
          messages,
          temperature,
          max_tokens: maxTokens,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        lastError = new Error(`OpenRouter error ${response.status}: ${errorText}`);
        
        // If rate limited or unauthorized, try fallback
        if (response.status === 429 || response.status === 401) {
          console.warn(`[OpenRouter] ${attemptModel} failed with ${response.status}, trying fallback...`);
          continue;
        }
        
        throw lastError;
      }

      const data: OpenRouterResponse = await response.json();
      const content = data.choices?.[0]?.message?.content || '';
      const usage = data.usage || { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 };

      // Track usage
      TokenUsageTracker.record({
        endpoint,
        model: attemptModel,
        promptTokens: usage.prompt_tokens,
        completionTokens: usage.completion_tokens,
        totalTokens: usage.total_tokens,
        timestamp: new Date(),
        userId,
      });

      // Cache successful response
      if (useCache && content) {
        const cacheKey = generateCacheKey(messages, attemptModel);
        setCachedResponse(cacheKey, content);
      }

      return {
        content,
        model: attemptModel,
        usage: {
          promptTokens: usage.prompt_tokens,
          completionTokens: usage.completion_tokens,
          totalTokens: usage.total_tokens,
        },
      };

    } catch (error) {
      lastError = error as Error;
      console.error(`[OpenRouter] ${attemptModel} request failed:`, error);
      // Continue to fallback model
    }
  }

  throw lastError || new Error('All OpenRouter models failed');
}
