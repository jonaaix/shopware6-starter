const modules = import.meta.glob('./js/*.js', { eager: true });
console.log(modules);

