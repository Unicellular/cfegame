<template>
  <div>hello {{ name }}</div>
</template>
<script>
export default {
  data() {
    return {
      name: "world"
    }
  },
  mounted() {
    console.log("event list is mounted")
  }
}
</script>
<style scoped>
div {
  font-size: 1em;
}
</style>