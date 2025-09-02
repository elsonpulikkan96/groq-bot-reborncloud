import '@/styles/globals.css';
import { appWithTranslation } from 'next-i18next';
import type { AppProps } from 'next/app';
import { Inter } from 'next/font/google';
import Head from 'next/head';
import { Toaster } from 'react-hot-toast';

const inter = Inter({ subsets: ['latin'] });

function App({ Component, pageProps }: AppProps<{}>) {
  return (
    <div className={inter.className}>
      <Head>
        <title>Reborncloud Groq Bot 🤖</title>
        <meta name="description" content="Reborncloud Groq Bot - AI Assistant powered by Groq" />
        <meta
          name="viewport"
          content="height=device-height ,width=device-width, initial-scale=1, user-scalable=no"
        />
        <link rel="icon" href="/favicon.ico" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-title" content="Reborncloud Groq Bot 🤖" />
      </Head>
      <Toaster />
      <Component {...pageProps} />
    </div>
  );
}

export default appWithTranslation(App);
