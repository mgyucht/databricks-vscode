package terraform

import (
	"errors"
	"fmt"

	tfjson "github.com/hashicorp/terraform-json"
)

func innerResources(s *tfjson.State,
	module *tfjson.StateModule,
	resType string, cb func(*Resource) error) (err error) {
	for _, r := range module.Resources {
		if r.Type != resType {
			continue
		}
		err = cb(&Resource{r})
		if err != nil {
			return
		}
	}
	for _, v := range module.ChildModules {
		err = innerResources(s, v, resType, cb)
		if err != nil {
			return
		}
	}
	return
}

func Resources(s *tfjson.State, resType string, cb func(*Resource) error) error {
	return innerResources(s, s.Values.RootModule, resType, cb)
}

func FindFirstResource[T any](s *tfjson.State, resType string, cb func(*Resource) *T) (result *T, err error) {
	if s.Values == nil {
		return nil, fmt.Errorf("no resources")
	}
	var done = errors.New("done")
	err = Resources(s, resType, func(r *Resource) error {
		result = cb(r)
		if result != nil {
			return done
		}
		return nil
	})
	if err != done {
		return nil, fmt.Errorf("not found")
	} else {
		return result, nil
	}
}

type Resource struct {
	*tfjson.StateResource
}

func (r *Resource) MustStr(key string) string {
	v, ok := r.AttributeValues[key]
	if !ok {
		return ""
	}
	return v.(string)
}
