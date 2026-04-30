import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { InvitationBindPage } from '../pages/invite/InvitationBindPage';
import { InvitationPage } from '../pages/invite/InvitationPage';
import { InvitationSuccessPage } from '../pages/invite/InvitationSuccessPage';
import './styles.css';

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/invite/:token" element={<InvitationPage />} />
        <Route path="/invite/:token/bind" element={<InvitationBindPage />} />
        <Route path="/invite/:token/success" element={<InvitationSuccessPage />} />
        <Route path="*" element={<Navigate to="/invite/demo" replace />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
);
