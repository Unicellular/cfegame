<template>
  <div :class="turn_owner">
    <span>第{{ turn_number }}回合</span>
    <div v-for="event in turn.events">
      <Event :event="event"></Event>
    </div>
  </div>
</template>
<script>
import Event from './event.vue'
export default {
  components: {
    Event
  },
  computed: {
    turn_owner() {
      if (this.turn.player == $('#player').data("id")) {
        return "player"
      }
      return "opponent"
    },
    turn_number() {
      return this.turn.number + 1
    }
  },
  props: ['turn']
}
</script>
<style scoped>
  .player {
    border: solid blue;
  }
  .opponent {
    border: solid red;
  }
</style>
