export const apiHeaders = (initData: string) => ({ 'Content-Type': 'application/json', 'x-init-data': initData })
export function handleError(error: Error) { console.error(error); return null; }

export function getLoadingState() { return { loading: true }; }
export function getErrorState() { return { error: true }; }