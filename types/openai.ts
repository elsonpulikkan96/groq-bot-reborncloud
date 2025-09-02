export interface OpenAIModel {
  id: string;
  name: string;
  maxLength: number; // maximum length of a message
  tokenLimit: number;
}

export enum OpenAIModelID {
  GPT_3_5 = 'gpt-3.5-turbo',
  GPT_4 = 'gpt-4',
  LLAMA_3_1_8B = 'llama-3.1-8b-instant',
  LLAMA_3_3_70B = 'llama-3.3-70b-versatile',
  GEMMA2_9B = 'gemma2-9b-it',
  COMPOUND_BETA = 'compound-beta',
}

// in case the `DEFAULT_MODEL` environment variable is not set or set to an unsupported model
export const fallbackModelID = OpenAIModelID.LLAMA_3_1_8B;

export const OpenAIModels: Record<OpenAIModelID, OpenAIModel> = {
  [OpenAIModelID.GPT_3_5]: {
    id: OpenAIModelID.GPT_3_5,
    name: 'GPT-3.5',
    maxLength: 12000,
    tokenLimit: 4000,
  },
  [OpenAIModelID.GPT_4]: {
    id: OpenAIModelID.GPT_4,
    name: 'GPT-4',
    maxLength: 24000,
    tokenLimit: 8000,
  },
  [OpenAIModelID.LLAMA_3_1_8B]: {
    id: OpenAIModelID.LLAMA_3_1_8B,
    name: 'Llama 3.1 8B (Fast)',
    maxLength: 120000,
    tokenLimit: 131072,
  },
  [OpenAIModelID.LLAMA_3_3_70B]: {
    id: OpenAIModelID.LLAMA_3_3_70B,
    name: 'Llama 3.3 70B (Powerful)',
    maxLength: 120000,
    tokenLimit: 131072,
  },
  [OpenAIModelID.GEMMA2_9B]: {
    id: OpenAIModelID.GEMMA2_9B,
    name: 'Gemma 2 9B',
    maxLength: 24000,
    tokenLimit: 8192,
  },
  [OpenAIModelID.COMPOUND_BETA]: {
    id: OpenAIModelID.COMPOUND_BETA,
    name: 'Compound Beta (Groq)',
    maxLength: 120000,
    tokenLimit: 131072,
  },
};
