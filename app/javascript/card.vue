<template>
  {{ element_name }}{{ card.level }}
</template>
<script>
export default {
  props: ['card'],
  computed: {
    element_name() {
      switch (this.card.element) {
        case 'metal': return '金'
        case 'tree': return '木'
        case 'water': return '水'
        case 'fire': return '火'
        case 'earth': return '土'
        default: return '無'
      }
    }
  }
}
</script>