import { OpenAIModel, OpenAIModelID, OpenAIModels } from '@/types/openai';
import { OPENAI_API_HOST } from '@/utils/app/const';

export const config = {
  runtime: 'edge',
};

const handler = async (req: Request): Promise<Response> => {
  try {
    const { key } = (await req.json()) as {
      key: string;
    };

    const response = await fetch(`${OPENAI_API_HOST}/v1/models`, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${key ? key : process.env.OPENAI_API_KEY}`,
        ...(process.env.OPENAI_ORGANIZATION && {
          'OpenAI-Organization': process.env.OPENAI_ORGANIZATION,
        })
      },
    });

    if (response.status === 401) {
      return new Response(response.body, {
        status: 500,
        headers: response.headers,
      });
    } else if (response.status !== 200) {
      console.error(
        `API returned an error ${
          response.status
        }: ${await response.text()}`,
      );
      throw new Error('API returned an error');
    }

    const json = await response.json();

    // Handle both OpenAI and Groq API response formats
    const modelsData = json.data || json;
    
    const models: OpenAIModel[] = [];
    
    // First, add our predefined models that are available
    for (const [key, value] of Object.entries(OpenAIModelID)) {
      const modelExists = modelsData.some((model: any) => model.id === value);
      if (modelExists && OpenAIModels[value as OpenAIModelID]) {
        models.push(OpenAIModels[value as OpenAIModelID]);
      }
    }
    
    // If no predefined models found, add available models dynamically
    if (models.length === 0) {
      const availableModels = modelsData
        .filter((model: any) => 
          model.id.includes('llama') || 
          model.id.includes('gemma') || 
          model.id.includes('compound') ||
          model.id.includes('gpt')
        )
        .slice(0, 5) // Limit to 5 models
        .map((model: any) => ({
          id: model.id,
          name: model.id.replace(/-/g, ' ').replace(/\b\w/g, (l: string) => l.toUpperCase()),
          maxLength: 120000,
          tokenLimit: 131072,
        }));
      
      models.push(...availableModels);
    }

    return new Response(JSON.stringify(models), { status: 200 });
  } catch (error) {
    console.error('Models API Error:', error);
    
    // Fallback: return default Groq models
    const fallbackModels = [
      { id: 'llama-3.1-8b-instant', name: 'Llama 3.1 8B (Fast)', maxLength: 120000, tokenLimit: 131072 },
      { id: 'llama-3.3-70b-versatile', name: 'Llama 3.3 70B (Powerful)', maxLength: 120000, tokenLimit: 131072 },
      { id: 'gemma2-9b-it', name: 'Gemma 2 9B', maxLength: 24000, tokenLimit: 8192 },
    ];
    
    return new Response(JSON.stringify(fallbackModels), { status: 200 });
  }
};

export default handler;
