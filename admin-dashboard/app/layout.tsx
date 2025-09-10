import './globals.css';
import React from 'react';
import Header from '../components/Header';
import Providers from './providers';

export const metadata = {
  title: 'Citizen Fix Admin',
  description: 'Admin dashboard for managing citizen reports',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <Header />
          <main className="container">
            {children}
          </main>
        </Providers>
      </body>
    </html>
  );
}
