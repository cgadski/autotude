use std::{cmp::Eq, default::Default, fmt::Debug};

use anyhow::{bail, Result};

// `trait_alias` not stable: https://github.com/rust-lang/rust/issues/41517
pub trait Data: Eq + Debug {}
impl<T: Eq + Debug> Data for T {}

#[derive(Debug)]
struct StateSinceTick<T: Data> {
    data: T,
    tick: i32,
}

#[derive(Default, Debug)]
pub struct StateTimeline<T: Data + Default> {
    history: Vec<StateSinceTick<T>>,
    next: T,
    tick: i32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct State<T: Data> {
    pub data: T,
    pub start_tick: i32,
    pub end_tick: i32,
}

impl<T: Data + Default> StateTimeline<T> {
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the state data for the current tick.
    pub fn set(&mut self, data: T) -> Result<()> {
        if self.next != T::default() && self.next != data {
            bail!("Multiple data for single tick to state timeline");
        }
        self.next = data;
        Ok(())
    }

    /// Mark the end of data collection for the current tick. Must be called each tick. If [set] was
    /// called since the last call to this, the provided data is considered current. Othwerwise, the
    /// data is considered default for the current tick.
    pub fn end_tick(&mut self, tick: i32) {
        let prev_state = self.history.last();
        if prev_state.is_none_or(|prev| prev.data != self.next) {
            self.history.push(StateSinceTick {
                data: std::mem::take(&mut self.next),
                tick,
            });
        } else {
            self.next = Default::default();
        }
        self.tick = tick;
    }

    pub fn iter(&self) -> impl Iterator<Item = State<&T>> {
        Iter {
            timeline: self,
            end_tick: self.tick + 1,
            i: 0,
        }
    }
}

pub struct Iter<'a, T: Data + Default> {
    timeline: &'a StateTimeline<T>,
    end_tick: i32,
    i: usize,
}

impl<'a, T: Data + Default> Iterator for Iter<'a, T> {
    type Item = State<&'a T>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.i >= self.timeline.history.len() {
            return None;
        }
        let i = self.timeline.history.len() - 1 - self.i;
        self.i += 1;
        if let Some(next) = self.timeline.history.get(i) {
            let end_tick = self.end_tick;
            self.end_tick = next.tick;
            Some(State {
                data: &next.data,
                start_tick: next.tick,
                end_tick,
            })
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn larger_example() -> Result<()> {
        let mut timeline = StateTimeline::<char>::new();
        timeline.set('a')?;
        timeline.end_tick(600);
        timeline.set('b')?;
        timeline.end_tick(601);
        timeline.set('b')?;
        timeline.end_tick(602);
        timeline.set('b')?;
        timeline.end_tick(603);
        timeline.end_tick(604);
        timeline.end_tick(605);
        timeline.end_tick(606);
        timeline.set('c')?;
        timeline.end_tick(607);
        timeline.set('c')?;
        timeline.end_tick(608);
        timeline.end_tick(609);
        timeline.end_tick(610);

        let actual: Vec<_> = timeline.iter().collect();
        let expected: Vec<_> = vec![
            state(&'\0', 609, 611),
            state(&'c', 607, 609),
            state(&'\0', 604, 607),
            state(&'b', 601, 604),
            state(&'a', 600, 601),
        ];
        assert_eq!(expected, actual);
        Ok(())
    }

    #[test]
    fn empty() {
        let timeline = StateTimeline::<()>::new();

        let mut actual = timeline.iter();
        assert_eq!(Option::None, actual.next());
    }

    #[test]
    fn singleton_tick() -> Result<()> {
        let mut timeline = StateTimeline::<Option<()>>::new();
        timeline.set(Some(()))?;
        timeline.end_tick(1);

        let mut actual = timeline.iter();
        assert_eq!(Some(state(&Some(()), 1, 2)), actual.next());
        assert_eq!(None, actual.next());
        Ok(())
    }

    #[test]
    fn singleton_data_for_multiple_ticks() -> Result<()> {
        let mut timeline = StateTimeline::<Option<()>>::new();
        timeline.set(Some(()))?;
        timeline.end_tick(1);
        timeline.set(Some(()))?;
        timeline.end_tick(2);

        let mut actual = timeline.iter();
        assert_eq!(Some(state(&Some(()), 1, 3)), actual.next());
        assert_eq!(None, actual.next());
        Ok(())
    }

    #[test]
    fn equal_data_represents_one_period() -> Result<()> {
        let mut timeline: StateTimeline<char> = StateTimeline::<char>::new();
        timeline.set('a')?;
        timeline.end_tick(1);
        timeline.set('b')?;
        timeline.end_tick(2);
        timeline.set('b')?;
        timeline.end_tick(3);

        let mut actual = timeline.iter();
        assert_eq!(Some(state(&'b', 2, 4)), actual.next());
        assert_eq!(Some(state(&'a', 1, 2)), actual.next());
        assert_eq!(None, actual.next());
        Ok(())
    }

    #[test]
    fn successive_missing_data_represents_one_period() -> Result<()> {
        let mut timeline = StateTimeline::<Option<()>>::new();
        timeline.set(Some(()))?;
        timeline.end_tick(1);
        timeline.end_tick(2);
        timeline.end_tick(3);

        let mut actual = timeline.iter();
        assert_eq!(Some(state(&None, 2, 4)), actual.next());
        assert_eq!(Some(state(&Some(()), 1, 2)), actual.next());
        assert_eq!(None, actual.next());
        Ok(())
    }

    #[test]
    fn setting_equal_data_twice_in_one_tick_is_allowed() -> Result<()> {
        let mut timeline = StateTimeline::<char>::new();
        timeline.set('a')?;
        timeline.set('a')?;
        timeline.end_tick(1);

        let mut actual = timeline.iter();
        assert_eq!(Some(state(&'a', 1, 2)), actual.next());
        assert_eq!(Option::None, actual.next());
        Ok(())
    }

    #[test]
    fn setting_different_data_twice_in_one_tick_is_not_allowed() -> Result<()> {
        let mut timeline = StateTimeline::<char>::new();
        timeline.set('a')?;

        let actual = timeline.set('b');
        assert!(actual.is_err());
        Ok(())
    }

    mod data_does_not_apply_until_end_tick {
        use super::*;

        #[test]
        fn when_empty() -> Result<()> {
            let mut timeline = StateTimeline::<()>::new();
            timeline.set(())?;

            let mut actual = timeline.iter();
            assert_eq!(Option::None, actual.next());
            Ok(())
        }

        #[test]
        fn when_not_empty() -> Result<()> {
            let mut timeline = StateTimeline::<Option<()>>::new();
            timeline.set(Some(()))?;
            timeline.end_tick(1);
            timeline.set(Some(()))?;

            let mut actual = timeline.iter();
            assert_eq!(Some(state(&Some(()), 1, 2)), actual.next());
            assert_eq!(None, actual.next());
            Ok(())
        }
    }

    fn state<T: Data>(data: T, start_tick: i32, end_tick: i32) -> State<T> {
        State {
            data,
            start_tick,
            end_tick,
        }
    }
}
