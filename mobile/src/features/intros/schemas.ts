import { z } from 'zod';

export const IntroNoteSchema = z.string().trim().min(80).max(400);
