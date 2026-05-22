import { supabase } from './supabaseClient';

const config = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_WEB_VAPID_KEY;
let firebaseModulesPromise: Promise<any> | null = null;

export const hasWebPushConfig = () => (
  Boolean(config.apiKey && config.projectId && config.messagingSenderId && config.appId && vapidKey)
);

const firebaseModules = async () => {
  if (!firebaseModulesPromise) {
    firebaseModulesPromise = Promise.all([
      import('firebase/app'),
      import('firebase/messaging'),
    ]).then(([appMod, messagingMod]) => ({
      // app helpers
      getApps: appMod.getApps,
      getApp: appMod.getApp,
      initializeApp: appMod.initializeApp,
      // messaging helpers
      isSupported: messagingMod.isSupported,
      getMessaging: messagingMod.getMessaging,
      getToken: messagingMod.getToken,
      onMessage: messagingMod.onMessage,
    }));
  }
  return firebaseModulesPromise;
};

const getDeviceId = () => {
  const key = 'gehu_web_push_device_id';
  if (typeof window === 'undefined') return null;
  let value = localStorage.getItem(key);
  if (!value) {
    value = (crypto as any).randomUUID ? (crypto as any).randomUUID() : Math.random().toString(36).slice(2);
    localStorage.setItem(key, value);
  }
  return value;
};

const swUrl = () => {
  const params = new URLSearchParams();
  Object.entries(config).forEach(([k, v]) => { if (v) params.set(k, String(v)); });
  return `/firebase-messaging-sw.js?${params.toString()}`;
};

const appInstance = (firebase: any) => {
  try {
    const apps = firebase.getApps?.() || [];
    if (apps.length > 0) return apps[0];
    return firebase.initializeApp(config);
  } catch (e) {
    // fallback: try getApp
    try { return firebase.getApp(); } catch { return firebase.initializeApp(config); }
  }
};

export async function registerWebPushToken({ requestPermission = false } = {}) {
  if (!hasWebPushConfig()) return { status: 'missing_config' };
  if (typeof window === 'undefined') return { status: 'unsupported' };
  if (!('Notification' in window) || !('serviceWorker' in navigator)) return { status: 'unsupported' };

  const firebase = await firebaseModules();
  const supported = await (firebase.isSupported ? firebase.isSupported() : Promise.resolve(false));
  if (!supported) return { status: 'unsupported' };

  let permission = Notification.permission;
  if (permission === 'default' && requestPermission) {
    permission = await Notification.requestPermission();
  }
  if (permission !== 'granted') return { status: permission };

  const registration = await navigator.serviceWorker.register(swUrl());
  const messaging = firebase.getMessaging(appInstance(firebase));
  const token = await firebase.getToken(messaging, { vapidKey, serviceWorkerRegistration: registration });
  if (!token) return { status: 'no_token' };

  const { error } = await supabase.rpc('api_register_fcm_token', {
    p_token: token,
    p_platform: 'WEB',
    p_device_id: getDeviceId(),
    p_app_version: process.env.NEXT_PUBLIC_APP_VERSION || 'web',
    p_user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
  });
  if (error) throw error;
  return { status: 'registered', token };
}

export async function listenForForegroundPush(callback: (payload: any) => void) {
  if (!hasWebPushConfig()) return () => {};
  if (typeof window === 'undefined') return () => {};
  const firebase = await firebaseModules();
  const supported = await (firebase.isSupported ? firebase.isSupported() : Promise.resolve(false));
  if (!supported) return () => {};
  const messaging = firebase.getMessaging(appInstance(firebase));
  return firebase.onMessage(messaging, callback);
}

export default {
  hasWebPushConfig,
  registerWebPushToken,
  listenForForegroundPush,
};
