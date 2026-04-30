import { useEffect } from 'react';
import { useInvitationStore } from '../../features/invitation/store';

export function useLoadInvitation(token: string | undefined) {
  const load = useInvitationStore((state) => state.load);

  useEffect(() => {
    if (!token) {
      return;
    }
    const controller = new AbortController();
    void load(token, controller.signal);
    return () => controller.abort();
  }, [load, token]);
}
