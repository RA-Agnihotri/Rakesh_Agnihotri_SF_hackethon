import { useState, useRef, useCallback } from 'react';

interface SpeechRecognitionEvent {
  results: SpeechRecognitionResultList;
  resultIndex: number;
}

interface SpeechRecognitionErrorEvent {
  error: string;
  message?: string;
}

type VoiceState = 'idle' | 'recording' | 'processing';

interface UseVoiceInputReturn {
  state: VoiceState;
  transcript: string;
  interimTranscript: string;
  error: string | null;
  isSupported: boolean;
  startRecording: () => void;
  stopRecording: () => void;
}

function getSpeechRecognition(): (new () => SpeechRecognition) | null {
  const w = window as any;
  return w.SpeechRecognition || w.webkitSpeechRecognition || null;
}

export function useVoiceInput(onResult: (text: string) => void): UseVoiceInputReturn {
  const [state, setState] = useState<VoiceState>('idle');
  const [transcript, setTranscript] = useState('');
  const [interimTranscript, setInterimTranscript] = useState('');
  const [error, setError] = useState<string | null>(null);
  const recognitionRef = useRef<SpeechRecognition | null>(null);

  const isSupported = !!getSpeechRecognition();

  const startRecording = useCallback(() => {
    const SpeechRecognition = getSpeechRecognition();
    if (!SpeechRecognition) {
      setError('Speech recognition is not supported in this browser.');
      return;
    }

    setError(null);
    setTranscript('');
    setInterimTranscript('');

    const recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;

    recognition.onstart = () => setState('recording');

    recognition.onresult = (event: SpeechRecognitionEvent) => {
      let interim = '';
      let final = '';
      for (let i = 0; i < event.results.length; i++) {
        const result = event.results[i];
        if (result.isFinal) {
          final += result[0].transcript;
        } else {
          interim += result[0].transcript;
        }
      }
      setTranscript(final);
      setInterimTranscript(interim);
    };

    recognition.onerror = (event: SpeechRecognitionErrorEvent) => {
      if (event.error === 'aborted') return;
      const messages: Record<string, string> = {
        'not-allowed': 'Microphone access denied. Please allow microphone permissions.',
        'no-speech': 'No speech detected. Please try again.',
        'network': 'Network error. Check your connection.',
      };
      setError(messages[event.error] || `Speech recognition error: ${event.error}`);
      setState('idle');
    };

    recognition.onend = () => {
      setState((prev) => {
        if (prev === 'recording') {
          // Ended naturally — deliver final transcript
          const finalText = (recognitionRef.current as any)?._finalText;
          if (finalText) onResult(finalText);
          return 'idle';
        }
        return prev;
      });
    };

    recognitionRef.current = recognition;
    recognition.start();
  }, [onResult]);

  const stopRecording = useCallback(() => {
    const recognition = recognitionRef.current;
    if (!recognition) return;

    setState('processing');

    // Gather whatever we have so far
    const finalText = (transcript + ' ' + interimTranscript).trim();
    recognition.stop();
    recognitionRef.current = null;

    if (finalText) {
      // Store for the onend handler fallback
      (recognition as any)._finalText = finalText;
      onResult(finalText);
    }

    setTimeout(() => setState('idle'), 300);
  }, [transcript, interimTranscript, onResult]);

  return {
    state,
    transcript,
    interimTranscript,
    error,
    isSupported,
    startRecording,
    stopRecording,
  };
}
